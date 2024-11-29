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
    "SPARK_DRIVER_BLOCK_MANAGER_PORT"
    "IMAGE"
    "NAMESPACE"
    "SPARK_DRIVER_SERVICE_ACCOUNT"
    "SPARK_DRIVER_POD_NAME"
)

for var in "${env_vars[@]}"; do
    echo "$var=${!var}"
done

export HADOOP_CLIENT_OPTS="-XX:+UseG1GC -XX:MaxGCPauseMillis=200 -Xmx4g -J-Xmx1024m -J-Xms512m"

# Ensure necessary directories for Spark exist
mkdir -p "${SPARK_LOG_DIR:-/tmp/spark-events}"

# Check for required environment variables and set defaults if not provided
: "${SPARK_MASTER:?SPARK_MASTER is not set}"
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
: "${SPARK_DRIVER_BLOCK_MANAGER_PORT:=7078}"
: "${IMAGE:?IMAGE is not set}"
: "${NAMESPACE:?NAMESPACE is not set}"
: "${SPARK_DRIVER_SERVICE_ACCOUNT:?SPARK_DRIVER_SERVICE_ACCOUNT is not set}"
: "${SPARK_DRIVER_POD_NAME:?SPARK_DRIVER_POD_NAME is not set}"

# Start Spark Thrift Server
"${SPARK_HOME}/bin/spark-submit" \
    --class org.apache.spark.sql.hive.thriftserver.HiveThriftServer2 \
    --master "k8s://https://${SPARK_MASTER}" \
    --deploy-mode client \
    --name thriftServer \
    --conf spark.kubernetes.file.upload.path=s3a://owalake/k8s-spark-scripts/spark-uploads \
    --conf spark.kubernetes.executor.podTemplateFile=s3a://owalake/k8s-spark-scripts/executor.yml \
    --conf spark.sql.warehouse.dir="${SPARK_WAREHOUSE_DIR}" \
    --conf spark.hadoop.hive.metastore.uris="${METASTORE_URIS}" \
    --conf spark.sql.hive.thriftServer.singleSession=false \
    --conf spark.sql.hive.thriftServer.enable.doAs=true \
    --conf spark.sql.server.port="${SPARK_SQL_SERVER_PORT:-10000}" \
    --conf spark.driver.port="${SPARK_DRIVER_PORT:-7078}" \
    --conf spark.ui.port="${SPARK_UI_PORT:-4040}" \
    --conf spark.driver.blockManager.port="${SPARK_DRIVER_BLOCK_MANAGER_PORT:-7079}" \
    --conf spark.driver.host="${SPARK_DRIVER_HOST}" \
    --conf spark.driver.bindAddress=0.0.0.0 \
    --conf spark.sql.catalogImplementation=hive \
    --conf spark.hadoop.fs.s3a.aws.credentials.provider=org.apache.hadoop.fs.s3a.SimpleAWSCredentialsProvider \
    --conf spark.sql.extensions=io.delta.sql.DeltaSparkSessionExtension \
    --conf spark.sql.catalog.spark_catalog=org.apache.spark.sql.delta.catalog.DeltaCatalog \
    --conf spark.sql.execution.arrow.pyspark.enabled=true \
    --conf spark.hadoop.fs.s3a.impl=org.apache.hadoop.fs.s3a.S3AFileSystem \
    --conf spark.hadoop.fs.s3a.access.key="${AWS_ACCESS_KEY_ID}" \
    --conf spark.hadoop.fs.s3a.secret.key="${AWS_SECRET_ACCESS_KEY}" \
    --conf spark.hadoop.fs.s3a.path.style.access=true \
    --conf spark.eventLog.enabled=true \
    --conf spark.eventLog.dir="${SPARK_LOG_DIR}" \
    --conf spark.driver.maxResultSize=32g \
    --conf spark.executor.memoryOverhead="${SPARK_EXECUTOR_MEMORY_OVERHEAD:-8g}" \
    --conf spark.executor.memory="${SPARK_EXECUTOR_MEMORY:-32g}" \
    --conf spark.executor.memory.request="${SPARK_EXECUTOR_MEMORY:-32g}" \
    --conf spark.executor.memory.limit="${SPARK_EXECUTOR_MEMORY:-32g}" \
    --conf spark.driver.memory.request="${SPARK_DRIVER_MEMORY:-32g}" \
    --conf spark.driver.memory.limit="${SPARK_DRIVER_MEMORY:-32g}" \
    --conf spark.driver.memory="${SPARK_DRIVER_MEMORY:-32g}" \
    --conf spark.executor.cores="${SPARK_EXECUTOR_CORES:-8}" \
    --conf spark.driver.cores="${SPARK_DRIVER_CORES:-8}" \
    --conf spark.sql.hive.thriftServer.async=true \
    --conf spark.sql.thriftServer.incrementalCollect=true \
    --conf spark.kubernetes.container.image="${IMAGE}" \
    --conf spark.kubernetes.container.image.pullPolicy=Always \
    --conf spark.kubernetes.driver.pod.name="${SPARK_DRIVER_POD_NAME}" \
    --conf spark.kubernetes.namespace="${NAMESPACE}" \
    --conf spark.dynamicAllocation.minExecutors=0 \
    --conf spark.dynamicAllocation.maxExecutors="${MAX_EXECUTORS:-5}" \
    --conf spark.kubernetes.executor.volumes.persistentVolumeClaim.spark-local-dir-1.options.claimName=OnDemand \
    --conf spark.kubernetes.executor.volumes.persistentVolumeClaim.spark-local-dir-1.options.storageClass=standard-rwo \
    --conf spark.kubernetes.executor.volumes.persistentVolumeClaim.spark-local-dir-1.options.sizeLimit=200Gi \
    --conf spark.kubernetes.executor.volumes.persistentVolumeClaim.spark-local-dir-1.options.accessModes[0]=ReadWriteOnce \
    --conf spark.kubernetes.executor.volumes.persistentVolumeClaim.spark-local-dir-1.mount.path=/tmp \
    --conf spark.kubernetes.executor.volumes.persistentVolumeClaim.spark-local-dir-1.mount.readOnly=false \
    --conf spark.kubernetes.authenticate.executor.serviceAccountName="${SPARK_DRIVER_SERVICE_ACCOUNT}" \
    --conf spark.kubernetes.executor.secretKeyRef.AWS_ACCESS_KEY_ID=thrift-spark-secret:aws-access-key-id \
    --conf spark.kubernetes.executor.secretKeyRef.AWS_SECRET_ACCESS_KEY=thrift-spark-secret:aws-secret-access-key \
    --conf spark.kubernetes.executor.secretKeyRef.METASTORE_URI=thrift-spark-secret:metastore-uri \
    --conf spark.kubernetes.executor.secretKeyRef.WAREHOUSE=thrift-spark-secret:warehouse \
    --conf spark.kubernetes.driver.ownPersistentVolumeClaim=false \
    --conf spark.serializer=org.apache.spark.serializer.KryoSerializer \
    --conf spark.sql.parquet.int96RebaseModeInWrite=LEGACY \
    --conf spark.network.timeout=600s \
    --conf spark.executor.heartbeatInterval=100s \
    --conf spark.sql.hive.resultset.use.unique.column.names=false \
    --conf spark.cleaner.verbose=true \
    --conf spark.cleaner.ttl=600 