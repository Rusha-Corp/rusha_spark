#!/bin/bash
set -e

# Check if required environment variables are set
: "${SPARK_WAREHOUSE_DIR:?Environment variable SPARK_WAREHOUSE_DIR is required}"
: "${METASTORE_URIS:?Environment variable METASTORE_URIS is required}"
: "${AWS_ACCESS_KEY_ID:?Environment variable AWS_ACCESS_KEY_ID is required}"
: "${AWS_SECRET_ACCESS_KEY:?Environment variable AWS_SECRET_ACCESS_KEY is required}"
: "${AWS_SESSION_TOKEN:?Environment variable AWS_SESSION_TOKEN is required}"

# Set default values for optional environment variables if not already set
export SPARK_MASTER=${SPARK_MASTER:-local[*]}
export SPARK_SQL_SERVER_PORT=${SPARK_SQL_SERVER_PORT:-10000}
export SPARK_DRIVER_MEMORY=${SPARK_DRIVER_MEMORY:-32g}
export SPARK_EXECUTOR_MEMORY=${SPARK_EXECUTOR_MEMORY:-32g}
export SPARK_EXECUTOR_CORES=${SPARK_EXECUTOR_CORES:-4}
export SPARK_HOME=${SPARK_HOME:-/opt/spark}
export SPARK_LOG_DIR=${SPARK_LOG_DIR:-/var/log/spark}
export SPARK_DRIVER_HOST=${SPARK_DRIVER_HOST:-localhost}
export SPARK_DRIVER_PORT=${SPARK_DRIVER_PORT:-7077}
export SPARK_BLOCKMANAGER_PORT=${SPARK_BLOCKMANAGER_PORT:-7078}
export SPARK_DRIVER_MAX_RESULT_SIZE=${SPARK_DRIVER_MAX_RESULT_SIZE:-4g}
export SPARK_EXECUTOR_MEMORY_OVERHEAD=${SPARK_EXECUTOR_MEMORY_OVERHEAD:-8g}

# Log environment variables (optional, for debugging purposes)
echo "Starting Spark Thrift Server with the following environment variables:"
echo "SPARK_MASTER=${SPARK_MASTER}"
echo "SPARK_SQL_SERVER_PORT=${SPARK_SQL_SERVER_PORT}"
echo "SPARK_DRIVER_MEMORY=${SPARK_DRIVER_MEMORY}"
echo "SPARK_EXECUTOR_MEMORY=${SPARK_EXECUTOR_MEMORY}"
echo "SPARK_EXECUTOR_CORES=${SPARK_EXECUTOR_CORES}"
echo "SPARK_WAREHOUSE_DIR=${SPARK_WAREHOUSE_DIR}"
echo "METASTORE_URIS=${METASTORE_URIS}"
echo "AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}"
echo "AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}"
echo "SPARK_HOME=${SPARK_HOME}"
echo "SPARK_LOG_DIR=${SPARK_LOG_DIR}"
echo "SPARK_DRIVER_HOST=${SPARK_DRIVER_HOST}"
echo "SPARK_DRIVER_PORT=${SPARK_DRIVER_PORT}"
echo "SPARK_BLOCKMANAGER_PORT=${SPARK_BLOCKMANAGER_PORT}"
echo "SPARK_DRIVER_MAX_RESULT_SIZE=${SPARK_DRIVER_MAX_RESULT_SIZE}"
echo "SPARK_EXECUTOR_MEMORY_OVERHEAD=${SPARK_EXECUTOR_MEMORY_OVERHEAD}"

# Ensure the necessary directories for Spark exist
mkdir -p ${SPARK_LOG_DIR}

export HADOOP_CLIENT_OPTS="-XX:+UseG1GC -XX:MaxGCPauseMillis=200 -Xmx56g -J-Xmx1024m -J-Xms512m"

# Start the Spark Thrift Server in standalone mode
"${SPARK_HOME}/bin/spark-submit" \
  --class org.apache.spark.sql.hive.thriftserver.HiveThriftServer2 \
  --master ${SPARK_MASTER} \
  --conf spark.sql.warehouse.dir=${SPARK_WAREHOUSE_DIR}/ \
  --conf spark.hadoop.hive.metastore.uris=${METASTORE_URIS} \
  --conf spark.sql.catalogImplementation=hive \
  --conf spark.sql.hive.thriftServer.singleSession=false \
  --conf spark.sql.hive.thriftServer.enable.doAs=true \
  --conf spark.hadoop.fs.s3a.aws.credentials.provider=org.apache.hadoop.fs.s3a.TemporaryAWSCredentialsProvider \
  --conf spark.hadoop.fs.s3a.impl=org.apache.hadoop.fs.s3a.S3AFileSystem \
  --conf spark.hadoop.fs.s3a.access.key=${AWS_ACCESS_KEY_ID} \
  --conf spark.hadoop.fs.s3a.secret.key=${AWS_SECRET_ACCESS_KEY} \
  --conf spark.hadoop.fs.s3a.session.token=${AWS_SESSION_TOKEN} \
  --conf spark.hadoop.fs.s3a.path.style.access=true \
  --conf spark.sql.extensions=io.delta.sql.DeltaSparkSessionExtension,org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions \
  --conf spark.sql.catalog.spark_catalog=org.apache.iceberg.spark.SparkSessionCatalog \
  --conf spark.sql.catalog.iceberg_catalog=org.apache.iceberg.spark.SparkCatalog \
  --conf spark.sql.catalog.iceberg_catalog.type=hive \
  --conf spark.sql.catalog.iceberg_catalog.uri=${METASTORE_URIS} \
  --conf spark.sql.catalog.iceberg_catalog.warehouse=${SPARK_WAREHOUSE_DIR}/iceberg_catalog \
  --conf spark.eventLog.enabled=true \
  --conf spark.eventLog.dir=${SPARK_LOG_DIR} \
  --conf spark.driver.memory=${SPARK_DRIVER_MEMORY} \
  --conf spark.driver.maxResultSize=${SPARK_DRIVER_MAX_RESULT_SIZE} \
  --conf spark.executor.memory=${SPARK_EXECUTOR_MEMORY} \
  --conf spark.executor.memoryOverhead=${SPARK_EXECUTOR_MEMORY_OVERHEAD} \
  --conf spark.sql.shuffle.partitions=200 \
  --conf spark.sql.hive.thriftServer.async=false \
  --conf spark.driver.host=${SPARK_DRIVER_HOST} \
  --conf spark.driver.port=${SPARK_DRIVER_PORT} \
  --conf spark.blockManager.port=${SPARK_BLOCKMANAGER_PORT} \
  --conf spark.rpc.askTimeout=600s \
  --conf spark.network.timeout=800s \
  --conf spark.sql.thriftServer.incrementalCollect=true
