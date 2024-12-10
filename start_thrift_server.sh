#!/bin/bash
set -e

# Check if required environment variables are set
: "${SPARK_WAREHOUSE_DIR:?Environment variable SPARK_WAREHOUSE_DIR is required}"
: "${METASTORE_URIS:?Environment variable METASTORE_URIS is required}"
: "${AWS_ACCESS_KEY_ID:?Environment variable AWS_ACCESS_KEY_ID is required}"
: "${AWS_SECRET_ACCESS_KEY:?Environment variable AWS_SECRET_ACCESS_KEY is required}"

# Log environment variables (optional, for debugging purposes)
echo "Starting Spark Thrift Server with the following environment variables:"
echo "SPARK_MASTER=${SPARK_MASTER:-local[*]}"
echo "SPARK_SQL_SERVER_PORT=${SPARK_SQL_SERVER_PORT:-10000}"
echo "SPARK_DRIVER_MEMORY=${SPARK_DRIVER_MEMORY:-32g}"
echo "SPARK_EXECUTOR_MEMORY=${SPARK_EXECUTOR_MEMORY:-32g}"
echo "SPARK_EXECUTOR_CORES=${SPARK_EXECUTOR_CORES:-4}"
echo "SPARK_WAREHOUSE_DIR=${SPARK_WAREHOUSE_DIR}"
echo "METASTORE_URIS=${METASTORE_URIS}"
echo "AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}"
echo "AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}"
echo "SPARK_HOME=${SPARK_HOME:-/opt/spark}"
echo "SPARK_LOG_DIR=${SPARK_LOG_DIR:-/var/log/spark}"
echo "SPARK_DRIVER_HOST=${SPARK_DRIVER_HOST:-localhost}"
echo "SPARK_DRIVER_PORT=${SPARK_DRIVER_PORT:-7077}"
echo "SPARK_BLOCKMANAGER_PORT=${SPARK_BLOCKMANAGER_PORT:-7078}"

export HADOOP_CLIENT_OPTS="-XX:+UseG1GC -XX:MaxGCPauseMillis=200 -Xmx56g -J-Xmx1024m -J-Xms512m"

# Ensure the necessary directories for Spark exist
SPARK_LOG_DIR=${SPARK_LOG_DIR:-/var/log/spark}
mkdir -p ${SPARK_LOG_DIR}

# Start the Spark Thrift Server in standalone mode
${SPARK_HOME}/bin/spark-submit \
  --class org.apache.spark.sql.hive.thriftserver.HiveThriftServer2 \
  --master "${SPARK_MASTER}" \
  --conf spark.sql.warehouse.dir=${SPARK_WAREHOUSE_DIR} \
  --conf spark.hadoop.hive.metastore.uris=${METASTORE_URIS} \
  --conf spark.sql.hive.thriftServer.singleSession=true \
  --conf spark.sql.hive.thriftServer.enable.doAs=false \
  --conf spark.sql.server.port=${SPARK_SQL_SERVER_PORT} \
  --conf spark.hadoop.fs.s3a.aws.credentials.provider=org.apache.hadoop.fs.s3a.SimpleAWSCredentialsProvider \
  --conf spark.hadoop.fs.s3a.impl=org.apache.hadoop.fs.s3a.S3AFileSystem \
  --conf spark.hadoop.fs.s3a.access.key=${AWS_ACCESS_KEY_ID} \
  --conf spark.hadoop.fs.s3a.secret.key=${AWS_SECRET_ACCESS_KEY} \
  --conf spark.hadoop.fs.s3a.path.style.access=true \
  --conf spark.sql.extensions=io.delta.sql.DeltaSparkSessionExtension \
  --conf spark.sql.catalog.spark_catalog=org.apache.spark.sql.delta.catalog.DeltaCatalog \
  --conf spark.eventLog.enabled=true \
  --conf spark.eventLog.dir=${SPARK_LOG_DIR} \
  --conf spark.driver.memory="${SPARK_DRIVER_MEMORY}" \
  --conf spark.driver.maxResultSize="${SPARK_DRIVER_MAX_RESULT_SIZE}" \
  --conf spark.executor.memory="${SPARK_EXECUTOR_MEMORY}" \
  --conf spark.executor.memoryOverhead="${SPARK_EXECUTOR_MEMORY_OVERHEAD}" \
  --conf spark.sql.shuffle.partitions=200 \
  --conf spark.sql.hive.thriftServer.async=false \
  --conf spark.driver.host=${SPARK_DRIVER_HOST} \
  --conf spark.driver.port=${SPARK_DRIVER_PORT} \
  --conf spark.blockManager.port=${SPARK_BLOCKMANAGER_PORT} \
  --conf spark.rpc.askTimeout=600s \
  --conf spark.network.timeout=800s \
  --conf spark.sql.thriftServer.incrementalCollect=true
