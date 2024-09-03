#!/bin/bash

# Exit on error
set -e

# Log environment variables (optional, for debugging purposes)
echo "Starting Spark Worker with the following environment variables:"
echo "SPARK_MASTER=${SPARK_MASTER}"
echo "SPARK_WORKER_CORES=${SPARK_WORKER_CORES}"
echo "SPARK_WORKER_MEMORY=${SPARK_WORKER_MEMORY}"
echo "SPARK_WORKER_PORT=${SPARK_WORKER_PORT}"
echo "SPARK_WORKER_WEBUI_PORT=${SPARK_WORKER_WEBUI_PORT}"
echo "SPARK_HOME=${SPARK_HOME}"
echo "SPARK_LOG_DIR=${SPARK_LOG_DIR}"

# Create the necessary directories for Spark if they don't exist
mkdir -p ${SPARK_LOG_DIR}

# Configure Spark to write event logs to the specified directory
export SPARK_DAEMON_JAVA_OPTS="${SPARK_DAEMON_JAVA_OPTS} -Dspark.eventLog.enabled=true -Dspark.eventLog.dir=${SPARK_LOG_DIR}"

# Start the Spark Worker
exec ${SPARK_HOME}/bin/spark-class org.apache.spark.deploy.worker.Worker \
    --cores ${SPARK_WORKER_CORES} \
    --memory ${SPARK_WORKER_MEMORY} \
    --port ${SPARK_WORKER_PORT} \
    --webui-port ${SPARK_WORKER_WEBUI_PORT} \
    ${SPARK_MASTER}
