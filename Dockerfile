# Set versions as arguments for flexibility
ARG SPARK_VERSION=3.5.3
ARG SCALA_LIBRARY_VERSION=2.12

# Base image for Spark
FROM spark:${SPARK_VERSION}-scala${SCALA_LIBRARY_VERSION}-java17-python3-ubuntu

# Redefine arguments for the build stage
ARG SCALA_LIBRARY_VERSION=2.13
ARG DELTA_SPARK_VERSION=3.2.1
ARG UNITYCATALOG_SPARK_VERSION=0.2.1
ARG SPARK_HADOOP_CLOUD_VERSION=3.5.3

# Define essential directories and environment variables
ARG SPARK_HOME=/opt/spark
ARG SPARK_LOG_DIR=/opt/spark/logs
ENV PATH="/opt/spark/bin:${PATH}"

# Download JAR dependencies using arguments
RUN curl -L --output delta-spark_${SCALA_LIBRARY_VERSION}-${DELTA_SPARK_VERSION}.jar \
    https://repo1.maven.org/maven2/io/delta/delta-spark_${SCALA_LIBRARY_VERSION}/${DELTA_SPARK_VERSION}/delta-spark_${SCALA_LIBRARY_VERSION}-${DELTA_SPARK_VERSION}.jar && \
    curl -L --output unitycatalog-spark_${SCALA_LIBRARY_VERSION}-${UNITYCATALOG_SPARK_VERSION}.jar \
    https://repo1.maven.org/maven2/io/unitycatalog/unitycatalog-spark_${SCALA_LIBRARY_VERSION}/${UNITYCATALOG_SPARK_VERSION}/unitycatalog-spark_${SCALA_LIBRARY_VERSION}-${UNITYCATALOG_SPARK_VERSION}.jar && \
    curl -L --output spark-hadoop-cloud_${SCALA_LIBRARY_VERSION}-${SPARK_HADOOP_CLOUD_VERSION}.jar \
    https://repo1.maven.org/maven2/org/apache/spark/spark-hadoop-cloud_${SCALA_LIBRARY_VERSION}/${SPARK_HADOOP_CLOUD_VERSION}/spark-hadoop-cloud_${SCALA_LIBRARY_VERSION}-${SPARK_HADOOP_CLOUD_VERSION}.jar

# Copy JARs to Spark JARs directory
RUN cp delta-spark_${SCALA_LIBRARY_VERSION}-${DELTA_SPARK_VERSION}.jar ${SPARK_HOME}/jars/ && \
    cp unitycatalog-spark_${SCALA_LIBRARY_VERSION}-${UNITYCATALOG_SPARK_VERSION}.jar ${SPARK_HOME}/jars/ && \
    cp spark-hadoop-cloud_${SCALA_LIBRARY_VERSION}-${SPARK_HADOOP_CLOUD_VERSION}.jar ${SPARK_HOME}/jars/

# Clean up downloaded files to reduce image size
RUN rm -f delta-spark_${SCALA_LIBRARY_VERSION}-${DELTA_SPARK_VERSION}.jar \
    unitycatalog-spark_${SCALA_LIBRARY_VERSION}-${UNITYCATALOG_SPARK_VERSION}.jar \
    spark-hadoop-cloud_${SCALA_LIBRARY_VERSION}-${SPARK_HADOOP_CLOUD_VERSION}.jar

# Install essential dependencies
USER root
RUN apt-get update && \
    apt-get install -y \
    libpq-dev python3-dev curl unzip zip git python3-pip && \
    pip3 install --upgrade pip && \
    pip3 install poetry && \
    apt-get install -y dnsutils

# Copy and set permissions for custom scripts
COPY start_thrift_server.sh /start_thrift_server.sh
COPY start_history_server.sh /start_history_server.sh
COPY start_spark_worker.sh /start_spark_worker.sh
COPY start_spark_master.sh /start_spark_master.sh
COPY start_thrift_server_k8s.sh /start_thrift_server_k8s.sh

# Configure Python
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3 1
