#!/bin/bash

# Exit on error
set -e

# Check if required environment variables are set
: "${SPARK_HOME:?SPARK_HOME is not set}"
: "${SPARK_MASTER_HOST:?SPARK_MASTER_HOST is not set}"
: "${SPARK_MASTER_PORT:?SPARK_MASTER_PORT is not set}"
: "${SPARK_MASTER_WEBUI_PORT:?SPARK_MASTER_WEBUI_PORT is not set}"
: "${SPARK_LOG_DIR:?SPARK_LOG_DIR is not set}"

# Log environment variables (optional, for debugging purposes)
echo "Starting Spark Master with the following environment variables:"
echo "SPARK_HOME=${SPARK_HOME}"
echo "SPARK_MASTER_HOST=${SPARK_MASTER_HOST}"
echo "SPARK_MASTER_PORT=${SPARK_MASTER_PORT}"
echo "SPARK_MASTER_WEBUI_PORT=${SPARK_MASTER_WEBUI_PORT}"
echo "SPARK_LOG_DIR=${SPARK_LOG_DIR}"

# Create the necessary directories for Spark if they don't exist
mkdir -p ${SPARK_LOG_DIR}

# Configure Spark to write event logs to the specified directory
export SPARK_DAEMON_JAVA_OPTS="${SPARK_DAEMON_JAVA_OPTS} -Dspark.eventLog.enabled=true -Dspark.eventLog.dir=${SPARK_LOG_DIR}"

# Start the Spark Master
exec ${SPARK_HOME}/bin/spark-class org.apache.spark.deploy.master.Master --ip $SPARK_MASTER_HOST --port $SPARK_MASTER_PORT --webui-port $SPARK_MASTER_WEBUI_PORT
