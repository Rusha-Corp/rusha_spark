FROM spark:3.5.0-scala2.12-java17-python3-ubuntu

# home
ARG SPARK_HOME=/opt/spark

# versions
ARG SPARK_VERSION=3.5.0
ARG HADOOP_VERSION=3.3.4
ARG AWS_SDK_VERSION=1.12.623
ARG SPARK_NLP_VERSION=5.2.0
ARG SPARK_LOG_DIR=/opt/spark/logs


# master
ARG SPARK_MASTER_LOG=/opt/spark/logs/spark-master.out
ARG SPARK_WORKER_LOG=/opt/spark/logs/spark-worker.out
ARG SPARK_MASTER_WEBUI_PORT=8080
ARG SPARK_WORKER_PORT=8081
ARG SPARK_WORKER_WEBUI_PORT=8082
ARG SPARK_MASTER_PORT=7077

# Set Spark environment variables
ENV SPARK_MASTER_PORT=${SPARK_MASTER_PORT} \
    SPARK_MASTER_WEBUI_PORT=${SPARK_MASTER_WEBUI_PORT} \
    SPARK_LOG_DIR=${SPARK_LOG_DIR} \
    SPARK_MASTER_LOG=${SPARK_MASTER_LOG} 

# Copy JAR files
RUN curl -L --output hadoop-aws-${HADOOP_VERSION}.jar  https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aws/${HADOOP_VERSION}/hadoop-aws-${HADOOP_VERSION}.jar 
RUN curl -L --output aws-java-sdk-bundle-${AWS_SDK_VERSION}.jar https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk-bundle/${AWS_SDK_VERSION}/aws-java-sdk-bundle-${AWS_SDK_VERSION}.jar 
RUN  curl -L --output spark-nlp_2.12-${SPARK_NLP_VERSION}.jar  https://repo1.maven.org/maven2/com/johnsnowlabs/nlp/spark-nlp_2.12/${SPARK_NLP_VERSION}/spark-nlp_2.12-${SPARK_NLP_VERSION}.jar 
RUN curl -L --output tensorflow-1.15.0.jar https://repo1.maven.org/maven2/org/tensorflow/tensorflow/1.15.0/tensorflow-1.15.0.jar 
RUN curl -L --output ndarray-0.4.0.jar https://repo1.maven.org/maven2/org/tensorflow/ndarray/0.4.0/ndarray-0.4.0.jar 
RUN curl -L --output tensorflow-core-platform-0.5.0.jar https://repo1.maven.org/maven2/org/tensorflow/tensorflow-core-platform/0.5.0/tensorflow-core-platform-0.5.0.jar 
RUN curl -L --output delta-spark_2.12-3.0.0.jar https://repo1.maven.org/maven2/io/delta/delta-spark_2.12/3.0.0/delta-spark_2.12-3.0.0.jar 
RUN curl -L --output delta-storage-3.0.0.jar  https://repo1.maven.org/maven2/io/delta/delta-storage/3.0.0/delta-storage-3.0.0.jar 
RUN curl -L --output scala-library-2.12.4.jar https://repo1.maven.org/maven2/org/scala-lang/scala-library/2.12.4/scala-library-2.12.4.jar 

RUN cp scala-library-2.12.4.jar ${SPARK_HOME}/jars/ && \
    cp delta-spark_2.12-3.0.0.jar ${SPARK_HOME}/jars/ && \
    cp delta-storage-3.0.0.jar ${SPARK_HOME}/jars/ && \
    cp tensorflow-core-platform-0.5.0.jar ${SPARK_HOME}/jars/ && \
    cp ndarray-0.4.0.jar ${SPARK_HOME}/jars/ && \
    cp tensorflow-1.15.0.jar ${SPARK_HOME}/jars/ && \
    cp spark-nlp_2.12-${SPARK_NLP_VERSION}.jar ${SPARK_HOME}/jars/ && \
    cp hadoop-aws-${HADOOP_VERSION}.jar ${SPARK_HOME}/jars/ && \
    cp aws-java-sdk-bundle-${AWS_SDK_VERSION}.jar ${SPARK_HOME}/jars/

# Remove unnecessary files
RUN rm -rf hadoop-aws-${HADOOP_VERSION}.jar aws-java-sdk-bundle-${AWS_SDK_VERSION}.jar spark-nlp_2.12-${SPARK_NLP_VERSION}.jar tensorflow-1.15.0.jar ndarray-0.4.0.jar tensorflow-core-platform-0.5.0.jar

# Set up spark directories
WORKDIR $SPARK_HOME
RUN mkdir -p $SPARK_LOG_DIR && \
    touch $SPARK_MASTER_LOG && \
    ln -sf /dev/stdout $SPARK_MASTER_LOG 

ENV PATH="/opt/spark/bin:${PATH}"

USER root
RUN apt update
RUN apt install dnsutils -y

USER spark
# Copy entrypoint script
COPY start-spark.sh /start-spark.sh

# Set up entrypoint
CMD ["/bin/bash", "/start-spark.sh"]
