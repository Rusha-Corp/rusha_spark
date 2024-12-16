# Set versions as arguments for flexibility
ARG SPARK_VERSION=3.5.3
ARG SCALA_LIBRARY_VERSION=2.12

# Base image for Spark
FROM spark:${SPARK_VERSION}-scala${SCALA_LIBRARY_VERSION}-java17-python3-ubuntu

# Redefine arguments for the build stage
ARG SCALA_LIBRARY_VERSION=2.12
ARG HADOOP_AWS_VERSION=3.4.1
ARG SPARK_NLP_VERSION=5.2.0
ARG DELTA_SPARK_VERSION=3.2.1
ARG UNITYCATALOG_SPARK_VERSION=0.2.1
ARG DELTA_STORAGE_VERSION=3.2.1
ARG ANTLR4_RUNTIME_VERSION=4.9.3
ARG AWS_SDK_BUNDLE_VERSION=2.24.6
ARG WILDFLY_OPENSSL_VERSION=1.1.3.Final

# Define essential directories and environment variables
ARG SPARK_HOME=/opt/spark
ARG SPARK_LOG_DIR=/opt/spark/logs
ENV PATH="/opt/spark/bin:${PATH}"

# Download JAR dependencies using arguments
RUN curl -L --output hadoop-aws-${HADOOP_AWS_VERSION}.jar \
    https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aws/${HADOOP_AWS_VERSION}/hadoop-aws-${HADOOP_AWS_VERSION}.jar && \
    curl -L --output spark-nlp_${SCALA_LIBRARY_VERSION}-${SPARK_NLP_VERSION}.jar \
    https://repo1.maven.org/maven2/com/johnsnowlabs/nlp/spark-nlp_${SCALA_LIBRARY_VERSION}/${SPARK_NLP_VERSION}/spark-nlp_${SCALA_LIBRARY_VERSION}-${SPARK_NLP_VERSION}.jar && \
    curl -L --output delta-spark_${SCALA_LIBRARY_VERSION}-${DELTA_SPARK_VERSION}.jar \
    https://repo1.maven.org/maven2/io/delta/delta-spark_${SCALA_LIBRARY_VERSION}/${DELTA_SPARK_VERSION}/delta-spark_${SCALA_LIBRARY_VERSION}-${DELTA_SPARK_VERSION}.jar && \
    curl -L --output unitycatalog-spark_${SCALA_LIBRARY_VERSION}-${UNITYCATALOG_SPARK_VERSION}.jar \
    https://repo1.maven.org/maven2/io/unitycatalog/unitycatalog-spark_${SCALA_LIBRARY_VERSION}/${UNITYCATALOG_SPARK_VERSION}/unitycatalog-spark_${SCALA_LIBRARY_VERSION}-${UNITYCATALOG_SPARK_VERSION}.jar && \
    curl -L --output delta-storage-${DELTA_STORAGE_VERSION}.jar \
    https://repo1.maven.org/maven2/io/delta/delta-storage/${DELTA_STORAGE_VERSION}/delta-storage-${DELTA_STORAGE_VERSION}.jar && \
    curl -L --output antlr4-runtime-${ANTLR4_RUNTIME_VERSION}.jar \
    https://repo1.maven.org/maven2/org/antlr/antlr4-runtime/${ANTLR4_RUNTIME_VERSION}/antlr4-runtime-${ANTLR4_RUNTIME_VERSION}.jar && \
    curl -L --output aws-sdk-bundle-${AWS_SDK_BUNDLE_VERSION}.jar \
    https://repo1.maven.org/maven2/software/amazon/awssdk/bundle/${AWS_SDK_BUNDLE_VERSION}/bundle-${AWS_SDK_BUNDLE_VERSION}.jar && \
    curl -L --output wildfly-openssl-${WILDFLY_OPENSSL_VERSION}.jar \
    https://repo1.maven.org/maven2/org/wildfly/openssl/wildfly-openssl/${WILDFLY_OPENSSL_VERSION}/wildfly-openssl-${WILDFLY_OPENSSL_VERSION}.jar && \
    curl -L --output hadoop-common-3.4.1.jar \
    https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-common/3.4.1/hadoop-common-3.4.1.jar && \
    curl -L --output hadoop-client-3.4.1.jar \
    https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-client/3.4.1/hadoop-client-3.4.1.jar

# Copy JARs to Spark JARs directory
RUN cp hadoop-aws-${HADOOP_AWS_VERSION}.jar ${SPARK_HOME}/jars/ && \
    cp spark-nlp_${SCALA_LIBRARY_VERSION}-${SPARK_NLP_VERSION}.jar ${SPARK_HOME}/jars/ && \
    cp delta-spark_${SCALA_LIBRARY_VERSION}-${DELTA_SPARK_VERSION}.jar ${SPARK_HOME}/jars/ && \
    cp unitycatalog-spark_${SCALA_LIBRARY_VERSION}-${UNITYCATALOG_SPARK_VERSION}.jar ${SPARK_HOME}/jars/ && \
    cp delta-storage-${DELTA_STORAGE_VERSION}.jar ${SPARK_HOME}/jars/ && \
    cp antlr4-runtime-${ANTLR4_RUNTIME_VERSION}.jar ${SPARK_HOME}/jars/ && \
    cp aws-sdk-bundle-${AWS_SDK_BUNDLE_VERSION}.jar ${SPARK_HOME}/jars/ && \
    cp wildfly-openssl-${WILDFLY_OPENSSL_VERSION}.jar ${SPARK_HOME}/jars/ && \
    cp hadoop-common-3.4.1.jar ${SPARK_HOME}/jars/ && \
    cp hadoop-client-3.4.1.jar ${SPARK_HOME}/jars/

# Clean up downloaded files to reduce image size
RUN rm -f hadoop-aws-${HADOOP_AWS_VERSION}.jar \
    spark-nlp_${SCALA_LIBRARY_VERSION}-${SPARK_NLP_VERSION}.jar \
    delta-spark_${SCALA_LIBRARY_VERSION}-${DELTA_SPARK_VERSION}.jar \
    unitycatalog-spark_${SCALA_LIBRARY_VERSION}-${UNITYCATALOG_SPARK_VERSION}.jar \
    delta-storage-${DELTA_STORAGE_VERSION}.jar \
    antlr4-runtime-${ANTLR4_RUNTIME_VERSION}.jar \
    aws-sdk-bundle-${AWS_SDK_BUNDLE_VERSION}.jar \
    wildfly-openssl-${WILDFLY_OPENSSL_VERSION}.jar \
    hadoop-common-3.4.1.jar \
    hadoop-client-3.4.1.jar

USER root
# Install essential dependencies
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

# USER spark

RUN update-alternatives --install /usr/bin/python python /usr/bin/python3 1