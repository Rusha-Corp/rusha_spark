#!/bin/bash
set -e

# Log environment variables (for debugging purposes)
echo "Starting Spark Thrift Server with the following environment variables:"
env_vars=(
  "SPARK_MASTER"
  "SPARK_SQL_SERVER_PORT"
  "SPARK_DRIVER_MEMORY"
  "SPARK_EXECUTOR_MEMORY"
  "SPARK_EXECUTOR_CORES"
  "SPARK_WAREHOUSE_DIR"
  "METASTORE_URIS"
  "AWS_ACCESS_KEY_ID"
  "AWS_SECRET_ACCESS_KEY"
  "SPARK_HOME"
  "SPARK_LOG_DIR"
  "SPARK_DRIVER_MAX_RESULT_SIZE"
  "SPARK_EXECUTOR_MEMORY_OVERHEAD"
  "SPARK_DRIVER_HOST"
  "SPARK_DRIVER_PORT"
  "SPARK_UI_PORT"
  "SPARK_BLOCKMANAGER_PORT"
)

export HADOOP_CLIENT_OPTS="-XX:+UseG1GC -XX:MaxGCPauseMillis=200 -Xmx4g -J-Xmx1024m -J-Xms512m"

# Ensure necessary directories for Spark exist
mkdir -p "${SPARK_LOG_DIR:-/tmp/spark-events}"

# Check for required environment variables and set defaults if not provided
: "${SPARK_MASTER:=local[*]}"
: "${SPARK_SQL_SERVER_PORT:=10000}"
: "${SPARK_DRIVER_MEMORY:=32g}"
: "${SPARK_EXECUTOR_MEMORY:=64g}"
: "${SPARK_EXECUTOR_CORES:=8}"
: "${SPARK_WAREHOUSE_DIR:?SPARK_WAREHOUSE_DIR is not set}"
: "${METASTORE_URIS:?METASTORE_URIS is not set}"
: "${AWS_ACCESS_KEY_ID:?AWS_ACCESS_KEY_ID is not set}"
: "${AWS_SECRET_ACCESS_KEY:?AWS_SECRET_ACCESS_KEY is not set}"
: "${SPARK_HOME:?SPARK_HOME is not set}"
: "${SPARK_LOG_DIR:=/tmp/spark-events}"
: "${SPARK_DRIVER_MAX_RESULT_SIZE:=128g}"
: "${SPARK_EXECUTOR_MEMORY_OVERHEAD:=8g}"
: "${SPARK_DRIVER_HOST:?SPARK_DRIVER_HOST is not set}"
: "${SPARK_DRIVER_PORT:=7077}"
: "${SPARK_UI_PORT:=4040}"
: "${SPARK_BLOCKMANAGER_PORT:=7078}"

for var in "${env_vars[@]}"; do
  echo "$var=${!var}"
done

export HADOOP_CLIENT_OPTS="-XX:+UseG1GC -XX:MaxGCPauseMillis=200 -Xmx4g -J-Xmx1024m -J-Xms512m"

# Ensure necessary directories for Spark exist
mkdir -p "${SPARK_LOG_DIR:-/tmp/spark-events}"

# Start the Spark Thrift Server in standalone mode
"${SPARK_HOME}/bin/spark-submit" \
  --class org.apache.spark.sql.hive.thriftserver.HiveThriftServer2 \
  --master "${SPARK_MASTER}" \
  --conf spark.sql.warehouse.dir="${SPARK_WAREHOUSE_DIR}" \
  --conf spark.hadoop.hive.metastore.uris="${METASTORE_URIS}" \
  --conf spark.sql.hive.thriftServer.singleSession=false \
  --conf spark.sql.server.port="${SPARK_SQL_SERVER_PORT}" \
  --conf spark.hadoop.fs.s3a.aws.credentials.provider=org.apache.hadoop.fs.s3a.SimpleAWSCredentialsProvider \
  --conf spark.hadoop.fs.s3a.impl=org.apache.hadoop.fs.s3a.S3AFileSystem \
  --conf spark.hadoop.fs.s3a.access.key="${AWS_ACCESS_KEY_ID}" \
  --conf spark.hadoop.fs.s3a.secret.key="${AWS_SECRET_ACCESS_KEY}" \
  --conf spark.hadoop.fs.s3a.path.style.access=true \
  --conf spark.sql.extensions=io.delta.sql.DeltaSparkSessionExtension \
  --conf spark.sql.catalog.spark_catalog=org.apache.spark.sql.delta.catalog.DeltaCatalog \
  --conf spark.eventLog.enabled=true \
  --conf spark.eventLog.dir="${SPARK_LOG_DIR}" \
  --conf spark.driver.memory="${SPARK_DRIVER_MEMORY}" \
  --conf spark.driver.maxResultSize="${SPARK_DRIVER_MAX_RESULT_SIZE}" \
  --conf spark.executor.memory="${SPARK_EXECUTOR_MEMORY}" \
  --conf spark.executor.memoryOverhead="${SPARK_EXECUTOR_MEMORY_OVERHEAD}" \
  --conf spark.driver.host="${SPARK_DRIVER_HOST}" \
  --conf spark.driver.port="${SPARK_DRIVER_PORT}" \
  --conf spark.blockManager.port="${SPARK_BLOCKMANAGER_PORT}" \
  --conf spark.sql.thriftServer.incrementalCollect=true
