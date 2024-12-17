# ------------------------------
# Stage 1: Build Fat JAR with SBT
# ------------------------------
FROM openjdk:17-jdk-slim AS build

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
COPY . /app
RUN sbt assembly


# ------------------------------
# Stage 2: Runtime Spark Setup
# ------------------------------
FROM openjdk:17-jdk-slim AS runtime

# Set Spark version, Hadoop version, and paths
ARG SPARK_VERSION=3.5.3
ARG HADOOP_VERSION=3
ARG SCALA_VERSION=2.12
ENV SPARK_HOME=/opt/spark
ENV PATH=${SPARK_HOME}/bin:${SPARK_HOME}/sbin:$PATH

# Install dependencies and Python 3.12
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget \
    tar \
    bash \
    gnupg \
    build-essential \
    libssl-dev \
    zlib1g-dev \
    libbz2-dev \
    libreadline-dev \
    libsqlite3-dev \
    curl \
    libncurses5-dev \
    libncursesw5-dev \
    xz-utils \
    tk-dev \
    libffi-dev \
    && rm -rf /var/lib/apt/lists/*

# Install Python 3.12
RUN set -eux; \
    PYTHON_VERSION=3.12.0; \
    PYTHON_TGZ_URL=https://www.python.org/ftp/python/$PYTHON_VERSION/Python-$PYTHON_VERSION.tgz; \
    \
    # Download and compile Python
    TMP_DIR=$(mktemp -d) && cd $TMP_DIR; \
    wget -q $PYTHON_TGZ_URL -O python.tgz; \
    tar -xf python.tgz; \
    cd Python-$PYTHON_VERSION; \
    ./configure --enable-optimizations; \
    make -j$(nproc); \
    make altinstall; \
    \
    # Clean up
    rm -rf $TMP_DIR; \
    ln -sf /usr/local/bin/python3.12 /usr/bin/python3; \
    ln -sf /usr/local/bin/pip3.12 /usr/bin/pip3

# Verify Python installation
RUN python3 --version && pip3 --version

# Download and verify Apache Spark
RUN set -eux; \
    SPARK_TGZ_URL=https://downloads.apache.org/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}-scala${SCALA_VERSION}.tgz; \
    SPARK_TGZ_ASC_URL=${SPARK_TGZ_URL}.asc; \
    \
    # Create temporary working directory
    SPARK_TMP="$(mktemp -d)" && cd "$SPARK_TMP"; \
    \
    # Download Spark and signature
    wget -q -O spark.tgz "$SPARK_TGZ_URL"; \
    wget -q -O spark.tgz.asc "$SPARK_TGZ_ASC_URL"; \
    \
    # Extract Spark and clean up
    tar -xzf spark.tgz -C /opt; \
    mv /opt/spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}-scala${SCALA_VERSION} ${SPARK_HOME}; \
    rm -rf "$SPARK_TMP"

# Add entrypoint scripts
COPY scripts/start_thrift_server.sh /start_thrift_server.sh
COPY scripts/start_history_server.sh /start_history_server.sh
COPY scripts/start_spark_worker.sh /start_spark_worker.sh
COPY scripts/start_spark_master.sh /start_spark_master.sh
COPY scripts/start_thrift_server_k8s.sh /start_thrift_server_k8s.sh

# Make scripts executable
RUN chmod +x /start_*.sh

# Copy Fat JAR dependencies from build stage
COPY --from=build /app/target/lib/* ${SPARK_HOME}/jars/

# Set default command
CMD ["bash"]
