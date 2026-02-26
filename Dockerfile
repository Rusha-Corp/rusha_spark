# ------------------------------
# Stage 1: Build Fat JAR with SBT
# ------------------------------
FROM eclipse-temurin:17-jdk-jammy AS build

RUN apt-get update && apt-get install -y curl gnupg2 apt-transport-https

# Install SBT
RUN echo "deb https://repo.scala-sbt.org/scalasbt/debian all main" | tee /etc/apt/sources.list.d/sbt.list
RUN echo "deb https://repo.scala-sbt.org/scalasbt/debian /" | tee /etc/apt/sources.list.d/sbt_old.list
RUN curl -sL "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x2EE0EA64E40A89B84B2DF73499E82A75642AC823" | apt-key add
RUN apt-get update
RUN apt-get install sbt -y

# Set working directory
WORKDIR /app

# Copy project files and build the Fat JAR
# Copy build definition files first for better caching
COPY build.sbt ./
COPY project/*.sbt project/*.scala project/build.properties project/
RUN sbt update  # Download dependencies first (cacheable layer)

# Copy source code and build
COPY src/ src/
RUN sbt assembly


# ------------------------------
# Stage 2: Runtime Spark Setup
# ------------------------------
FROM eclipse-temurin:17-jdk-jammy AS runtime

# Set Spark version, Hadoop version, and paths
ARG SPARK_VERSION=3.5.8
ARG HADOOP_VERSION=3
ARG HADOOP_NATIVE_VERSION=3.3.4
ARG SCALA_VERSION=2.12
ENV SPARK_HOME=/opt/spark
ENV HADOOP_HOME=/opt/hadoop
ENV HADOOP_COMMON_LIB_NATIVE_DIR=${HADOOP_HOME}/lib/native
ENV HADOOP_OPTS="${HADOOP_OPTS} -Djava.library.path=${HADOOP_HOME}/lib/native"
ENV LD_LIBRARY_PATH=${HADOOP_HOME}/lib/native
ENV PATH=${SPARK_HOME}/bin:${SPARK_HOME}/sbin:$PATH


# Install system dependencies and build Python 3.12
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        # Core utilities
        wget tar bash curl gnupg procps netcat \
        # Hadoop native runtime deps
        libsnappy1v5 liblz4-1 libzstd1 libbz2-1.0 libssl3 libisal2 \
        # PostgreSQL development (needed for psycopg2)
        libpq-dev postgresql-client \
        # Build dependencies for Python and C extensions
        build-essential libssl-dev zlib1g-dev libbz2-dev \
        libreadline-dev libsqlite3-dev libffi-dev && \
    PYTHON_VERSION=3.12.12 && \
    PYTHON_TGZ_URL="https://www.python.org/ftp/python/$PYTHON_VERSION/Python-$PYTHON_VERSION.tgz" && \
    TMP_DIR=$(mktemp -d) && cd "$TMP_DIR" && \
    wget -q "$PYTHON_TGZ_URL" -O python.tgz && \
    tar -xf python.tgz && \
    cd "Python-$PYTHON_VERSION" && \
    ./configure --enable-optimizations --prefix=/usr/local && \
    make -j$(nproc) && \
    make altinstall && \
    cd / && rm -rf "$TMP_DIR" && \
    # Create symbolic links
    ln -sf /usr/local/bin/python3.12 /usr/bin/python3 && \
    ln -sf /usr/local/bin/pip3.12 /usr/bin/pip3 && \
    # Clean apt cache but keep build tools for Python packages
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    # Verify installation
    python3 --version && pip3 --version

# Download and install Spark in a single layer
RUN SPARK_TGZ_URL="https://archive.apache.org/dist/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz" && \
    wget -qO- "$SPARK_TGZ_URL" | tar -xz -C /opt && \
    mv /opt/spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION} ${SPARK_HOME}

# Download and install Hadoop native libs
RUN HADOOP_TGZ_URL="https://archive.apache.org/dist/hadoop/common/hadoop-${HADOOP_NATIVE_VERSION}/hadoop-${HADOOP_NATIVE_VERSION}.tar.gz" && \
    mkdir -p ${HADOOP_HOME}/lib/native && \
    TMP_DIR=$(mktemp -d) && cd "$TMP_DIR" && \
    wget -qO- "$HADOOP_TGZ_URL" | tar -xz && \
    cp -r hadoop-${HADOOP_NATIVE_VERSION}/lib/native/* ${HADOOP_HOME}/lib/native/ && \
    # Move common JARs to HADOOP_HOME/lib for visibility to some tools
    cp hadoop-${HADOOP_NATIVE_VERSION}/share/hadoop/common/hadoop-common-${HADOOP_NATIVE_VERSION}.jar ${HADOOP_HOME}/lib/ && \
    cd / && rm -rf "$TMP_DIR"
# Add entrypoint scripts
COPY scripts/*.sh /
# Make scripts executable
RUN chmod +x /*.sh

# Copy Fat JAR dependencies from build stage
COPY --from=build /app/target/lib/* ${SPARK_HOME}/jars/

# Ensure Hadoop and AWS SDK version alignment by removing conflicting versions
RUN find ${SPARK_HOME}/jars/ -name "hadoop-*-3.4.0.jar" -delete

# Install Python dependencies using Poetry
# Install poetry, export dependencies, install them, then cleanup
RUN pip3 install --no-cache-dir poetry && \
    poetry self add poetry-plugin-export

COPY pyproject.toml poetry.lock ./

RUN poetry export --without-hashes -f requirements.txt -o requirements.txt && \
    pip3 install --no-cache-dir -r requirements.txt && \
    pip3 uninstall -y poetry && \
    # Remove build dependencies after all Python packages are installed
    apt-get purge -y build-essential libssl-dev zlib1g-dev \
        libbz2-dev libreadline-dev libsqlite3-dev libffi-dev && \
    apt-get autoremove -y && \
    LIBSSL_DEB_URL="https://launchpadlibrarian.net/715615335/libssl1.1_1.1.1f-1ubuntu2.22_amd64.deb" && \
    wget -q -O /tmp/libssl1.1.deb "$LIBSSL_DEB_URL" && \
    dpkg -i /tmp/libssl1.1.deb || (apt-get -f install -y && dpkg -i /tmp/libssl1.1.deb) && \
    rm -f /tmp/libssl1.1.deb && \
    ln -sf /usr/lib/x86_64-linux-gnu/libcrypto.so.1.1 /usr/lib/x86_64-linux-gnu/libcrypto.so && \
    apt-get clean && \
    # Clean all caches
    rm -rf /root/.cache/pip /root/.cache/pypoetry requirements.txt /var/lib/apt/lists/*

# Set default command
CMD ["bash"]
