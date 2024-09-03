#!/bin/bash

# Exit on error
set -e

# Log environment variables (optional, for debugging purposes)
echo "Starting Spark History Server with the following environment variables:"
echo "SPARK_HISTORY_OPTS=${SPARK_HISTORY_OPTS}"
echo "SPARK_HOME=${SPARK_HOME}"
echo "SPARK_LOG_DIR=${SPARK_LOG_DIR}"

# Ensure the event log directory is specified
export SPARK_HISTORY_OPTS="${SPARK_HISTORY_OPTS} -Dspark.history.fs.logDirectory=${SPARK_LOG_DIR} -Dspark.history.fs.update.interval=10s -Dspark.io.compression.codec=snappy"

# Create the necessary directories for Spark if they don't exist
mkdir -p ${SPARK_LOG_DIR}

# Start the Spark History Server
exec ${SPARK_HOME}/bin/spark-class org.apache.spark.deploy.history.HistoryServer
