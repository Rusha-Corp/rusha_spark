#!/bin/bash
set -e

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

# Create the necessary directories for Spark if they don't exist
mkdir -p ${SPARK_LOG_DIR}

# Start the Spark Thrift Server with event logging enabled
${SPARK_HOME}/bin/spark-submit \
  --class org.apache.spark.sql.hive.thriftserver.HiveThriftServer2 \
  --master ${SPARK_MASTER} \
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
  --conf spark.driver.memory=${SPARK_DRIVER_MEMORY:-2g} \
  --conf spark.driver.cores=${SPARK_DRIVER_CORES:-2} \
  --conf spark.executor.memory=${SPARK_EXECUTOR_MEMORY:-4g} \
  --conf spark.executor.cores=${SPARK_EXECUTOR_CORES:-2} \
  --conf spark.executor.instances=${SPARK_EXECUTOR_INSTANCES:-2} \
  --conf spark.driver.maxResultSize=32g \
  --conf spark.driver.offHeap.enabled=true \
  --conf spark.driver.offHeap.size=8g \
  --conf spark.memory.fraction=0.5 \  
  --conf spark.sql.autoBroadcastJoinThreshold=-1 \  # Disable auto-broadcast joins for large datasets
  --conf spark.sql.shuffle.partitions=50 \  # Reduce shuffle partitions to lower memory usage
  --conf spark.sql.hive.thriftServer.async=false 
