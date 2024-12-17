# Base image with SBT and OpenJDK
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

# Copy project files
COPY . /app

# Build Fat JAR
RUN sbt assembly


# FROM openjdk:17-jdk-slim AS runtime

# # Copy Fat JAR from previous stage
# COPY --from=0 /app/target/scala-2.13/spark-unity-catalog-1.0.jar /opt/spark/jars/

# ENV PATH="/opt/spark/bin:${PATH}"
# ARG SPARK_HOME=/opt/spark

# RUN apt update
# RUN apt install dnsutils -y

# # Install dependencies
# RUN apt-get update && \
#     apt-get install -y python3.11 \
#     libpq-dev python3-dev curl unzip zip git python3-pip

# RUN pip3 install --upgrade pip
# RUN pip3 install poetry

# # Copy entrypoint script
# COPY scripts/start_thrift_server.sh /start_thrift_server.sh
# COPY scripts/start_history_server.sh /start_history_server.sh
# COPY scripts/start_spark_worker.sh /start_spark_worker.sh
# COPY scripts/start_spark_master.sh /start_spark_master.sh
# COPY scripts/start_thrift_server_k8s.sh /start_thrift_server_k8s.sh



