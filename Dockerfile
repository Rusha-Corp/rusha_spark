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
ARG SPARK_VERSION=3.5.3
ARG HADOOP_VERSION=3
ARG SCALA_VERSION=2.12
ENV SPARK_HOME=/opt/spark
ENV PATH=${SPARK_HOME}/bin:${SPARK_HOME}/sbin:$PATH


# Install system dependencies and build Python 3.12
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        # Core utilities
        wget tar bash curl gnupg procps netcat \
        # PostgreSQL development (needed for psycopg2)
        libpq-dev postgresql-client \
        # Build dependencies for Python and C extensions
        build-essential libssl-dev zlib1g-dev libbz2-dev \
        libreadline-dev libsqlite3-dev libffi-dev && \
    # Build Python 3.12 from source
    PYTHON_VERSION=3.12.0 && \
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
    SPARK_TMP="$(mktemp -d)" && \
    cd "$SPARK_TMP" && \
    wget -q -O spark.tgz "$SPARK_TGZ_URL" && \
    tar -xzf spark.tgz -C /opt && \
    mv /opt/spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION} ${SPARK_HOME} && \
    rm -rf "$SPARK_TMP"
# Add entrypoint scripts
COPY scripts/*.sh /
# Make scripts executable
RUN chmod +x /*.sh

# Copy Fat JAR dependencies from build stage
COPY --from=build /app/target/lib/* ${SPARK_HOME}/jars/

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
    apt-get clean && \
    # Clean all caches
    rm -rf /root/.cache/pip /root/.cache/pypoetry requirements.txt /var/lib/apt/lists/*

# Set default command
CMD ["bash"]
