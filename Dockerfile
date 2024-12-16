# versions
ARG SPARK_VERSION=3.5.3
ARG HADOOP_AWS_VERSION=3.4.1
ARG SPARK_NLP_VERSION=5.2.0
ARG DELTA_SPARK_VERSION=3.2.1
ARG UNITYCATALOG_SPARK_VERSION=0.2.1
ARG SCALA_LIBRARY_VERSION=2.12

FROM spark:${SPARK_VERSION}-scala${SCALA_LIBRARY_VERSION}-java17-python3-ubuntu

# home
ARG SPARK_HOME=/opt/spark
ARG SPARK_LOG_DIR=/opt/spark/logs

# Copy JAR files
RUN curl -L --output hadoop-aws-${HADOOP_VERSION}.jar  https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aws/${HADOOP_VERSION}/hadoop-aws-${HADOOP_VERSION}.jar 
RUN curl -L --output spark-nlp_${SCALA_LIBRARY_VERSION}-${SPARK_NLP_VERSION}.jar  https://repo1.maven.org/maven2/com/johnsnowlabs/nlp/spark-nlp_${SCALA_LIBRARY_VERSION}/${SPARK_NLP_VERSION}/spark-nlp_${SCALA_LIBRARY_VERSION}-${SPARK_NLP_VERSION}.jar 
RUN curl -L --output delta-spark_${SCALA_LIBRARY_VERSION}-${DELTA_SPARK_VERSION}.jar https://repo1.maven.org/maven2/io/delta/delta-spark_${SCALA_LIBRARY_VERSION}/${DELTA_SPARK_VERSION}/delta-spark_${SCALA_LIBRARY_VERSION}-${DELTA_SPARK_VERSION}.jar 
RUN curl -L --output unitycatalog-spark_${SCALA_LIBRARY_VERSION}-${UNITYCATALOG_SPARK_VERSION}.jar  https://repo1.maven.org/maven2/io/unitycatalog/unitycatalog-spark_${SCALA_LIBRARY_VERSION}/${UNITYCATALOG_SPARK_VERSION}/unitycatalog-spark_${SCALA_LIBRARY_VERSION}-${UNITYCATALOG_SPARK_VERSION}.jar

RUN cp delta-spark_${SCALA_LIBRARY_VERSION}-${DELTA_SPARK_VERSION}.jar ${SPARK_HOME}/jars/ && \
    cp spark-nlp_${SCALA_LIBRARY_VERSION}-${SPARK_NLP_VERSION}.jar ${SPARK_HOME}/jars/ && \
    cp hadoop-aws-${HADOOP_VERSION}.jar ${SPARK_HOME}/jars/ && \
    cp unitycatalog-spark_${SCALA_LIBRARY_VERSION}-${UNITYCATALOG_SPARK_VERSION}.jar ${SPARK_HOME}/jars/

# Remove unnecessary files
RUN rm -rf hadoop-aws-${HADOOP_VERSION}.jar \
    aws-java-sdk-bundle-${AWS_SDK_VERSION}.jar \
    spark-nlp_${SCALA_LIBRARY_VERSION}-${SPARK_NLP_VERSION}.jar \
    tensorflow-${TENSORFLOW_VERSION}.jar \
    ndarray-${NDARRAY_VERSION}.jar \
    tensorflow-core-platform-${TENSORFLOW_CORE_PLATFORM_VERSION}.jar \
    delta-spark_${SCALA_LIBRARY_VERSION}-${DELTA_SPARK_VERSION}.jar \
    delta-storage-${DELTA_STORAGE_VERSION}.jar \
    scala-library-${SCALA_LIBRARY_VERSION}.jar \
    unitycatalog-spark_${SCALA_LIBRARY_VERSION}-${UNITYCATALOG_SPARK_VERSION}.jar

# Set up spark directories
ENV PATH="/opt/spark/bin:${PATH}"

USER root
RUN apt update
RUN apt install dnsutils -y

# Install dependencies
RUN apt-get update && \
    apt-get install -y \
    libpq-dev python3-dev curl unzip zip git python3-pip

RUN pip3 install --upgrade pip
RUN pip3 install poetry

# Copy entrypoint script
COPY start_thrift_server.sh /start_thrift_server.sh
COPY start_history_server.sh /start_history_server.sh
COPY start_spark_worker.sh /start_spark_worker.sh
COPY start_spark_master.sh /start_spark_master.sh
COPY start_thrift_server_k8s.sh /start_thrift_server_k8s.sh

RUN chmod +x /start_thrift_server.sh && \
    chmod +x /start_history_server.sh && \
    chmod +x /start_spark_worker.sh && \
    chmod +x /start_spark_master.sh && \
    chmod +x /start_thrift_server_k8s.sh 