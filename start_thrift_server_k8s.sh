#!/bin/bash
set -e

# Log environment variables (for debugging purposes)
echo "Starting Spark Thrift Server with the following environment variables:"
echo "SPARK_MASTER=${SPARK_MASTER}"
echo "SPARK_SQL_SERVER_PORT=${SPARK_SQL_SERVER_PORT:-10000}"
echo "SPARK_DRIVER_MEMORY=${SPARK_DRIVER_MEMORY:-8g}"
echo "SPARK_EXECUTOR_MEMORY=${SPARK_EXECUTOR_MEMORY:-16g}"
echo "SPARK_EXECUTOR_CORES=${SPARK_EXECUTOR_CORES:-4}"
echo "SPARK_WAREHOUSE_DIR=${SPARK_WAREHOUSE_DIR}"
echo "METASTORE_URIS=${METASTORE_URIS}"
echo "AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}"
echo "AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}"
echo "SPARK_HOME=${SPARK_HOME}"
echo "SPARK_LOG_DIR=${SPARK_LOG_DIR:-/tmp/spark-events}"
echo "SPARK_DRIVER_MAX_RESULT_SIZE=${SPARK_DRIVER_MAX_RESULT_SIZE:-32g}"
echo "SPARK_EXECUTOR_MEMORY_OVERHEAD=${SPARK_EXECUTOR_MEMORY_OVERHEAD:-4g}"
echo "SPARK_DRIVER_HOST=${SPARK_DRIVER_HOST}"
echo "SPARK_DRIVER_PORT=${SPARK_DRIVER_PORT}"
echo "SPARK_UI_PORT=${SPARK_UI_PORT}"
echo "SPARK_DRIVER_BLOCK_MANAGER_PORT=${SPARK_DRIVER_BLOCK_MANAGER_PORT}"
echo "IMAGE=${IMAGE}"
echo "NAMESPACE=${NAMESPACE}"
echo "SPARK_DRIVER_SERVICE_ACCOUNT=${SPARK_DRIVER_SERVICE_ACCOUNT}"

export HADOOP_CLIENT_OPTS="-XX:+UseG1GC -XX:MaxGCPauseMillis=200 -Xmx56g -J-Xmx1024m -J-Xms512m"

# Ensure necessary directories for Spark exist
mkdir -p ${SPARK_LOG_DIR}

# Start the Spark Thrift Server in standalone mode
${SPARK_HOME}/bin/spark-submit \
    --class org.apache.spark.sql.hive.thriftserver.HiveThriftServer2 \
    --master k8s://https://${SPARK_MASTER} \
    --deploy-mode client \
    --name thriftServer \
    --conf spark.kubernetes.file.upload.path=s3a://owalake/k8s-spark-scripts/spark-uploads \
    --conf spark.kubernetes.executor.podTemplateFile=s3a://owalake/k8s-spark-scripts/executor.yml \
    --conf spark.sql.warehouse.dir=${SPARK_WAREHOUSE_DIR} \
    --conf spark.hadoop.hive.metastore.uris=${METASTORE_URIS} \
    --conf spark.sql.hive.thriftServer.singleSession=true \
    --conf spark.sql.hive.thriftServer.enable.doAs=false \
    --conf spark.sql.server.port=${SPARK_SQL_SERVER_PORT:-10000} \
    --conf spark.driver.port=${SPARK_DRIVER_PORT} \
    --conf spark.ui.port=${SPARK_UI_PORT} \
    --conf spark.driver.blockManager.port=${SPARK_DRIVER_BLOCK_MANAGER_PORT} \
    --conf spark.driver.host=${SPARK_DRIVER_HOST} \
    --conf spark.driver.bindAddress=0.0.0.0 \
    --conf spark.sql.catalogImplementation=hive \
    --conf spark.hadoop.fs.s3a.aws.credentials.provider=org.apache.hadoop.fs.s3a.SimpleAWSCredentialsProvider \
    --conf spark.sql.extensions=io.delta.sql.DeltaSparkSessionExtension \
    --conf spark.sql.catalog.spark_catalog=org.apache.spark.sql.delta.catalog.DeltaCatalog \
    --conf spark.sql.execution.arrow.pyspark.enabled=true \
    --conf spark.hadoop.fs.s3a.impl=org.apache.hadoop.fs.s3a.S3AFileSystem \
    --conf spark.hadoop.fs.s3a.access.key=${AWS_ACCESS_KEY_ID} \
    --conf spark.hadoop.fs.s3a.secret.key=${AWS_SECRET_ACCESS_KEY} \
    --conf spark.hadoop.fs.s3a.path.style.access=true \
    --conf spark.sql.extensions=io.delta.sql.DeltaSparkSessionExtension \
    --conf spark.sql.catalog.spark_catalog=org.apache.spark.sql.delta.catalog.DeltaCatalog \
    --conf spark.eventLog.enabled=true \
    --conf spark.eventLog.dir=${SPARK_LOG_DIR} \
    --conf spark.driver.maxResultSize=${SPARK_DRIVER_MAX_RESULT_SIZE:-32g} \
    --conf spark.executor.memoryOverhead=${SPARK_EXECUTOR_MEMORY_OVERHEAD:-4g} \
    --conf spark.executor.memory=${SPARK_EXECUTOR_MEMORY:-8g} \
    --conf spark.driver.memory=${SPARK_DRIVER_MEMORY:-8g} \
    --conf spark.executor.cores=${SPARK_EXECUTOR_CORES:-2} \
    --conf spark.driver.cores=${SPARK_DRIVER_CORES:-2} \
    --conf spark.sql.hive.thriftServer.async=true \
    --conf spark.sql.thriftServer.incrementalCollect=true \
    --conf spark.kubernetes.container.image=${IMAGE} \
    --conf spark.kubernetes.container.image.pullPolicy=Always \
    --conf spark.kubernetes.driver.pod.name=${SPARK_DRIVER_POD_NAME} \
    --conf spark.kubernetes.namespace=${NAMESPACE} \
    --conf spark.kubernetes.executor.limit.cores=68 \
    --conf spark.kubernetes.executor.limit.memory=224g \
    --conf spark.dynamicAllocation.enabled=true \
    --conf spark.dynamicAllocation.minExecutors=1 \
    --conf spark.dynamicAllocation.maxExecutors=10 \
    --conf spark.dynamicAllocation.initialExecutors=1 \
    --conf spark.dynamicAllocation.executorIdleTimeout=60s \
    --conf spark.dynamicAllocation.cachedExecutorIdleTimeout=60s \
    --conf spark.kubernetes.executor.volumes.persistentVolumeClaim.spark-local-dir-1.options.claimName=OnDemand \
    --conf spark.kubernetes.executor.volumes.persistentVolumeClaim.spark-local-dir-1.options.storageClass=standard-rwo \
    --conf spark.kubernetes.executor.volumes.persistentVolumeClaim.spark-local-dir-1.options.sizeLimit=50Gi \
    --conf spark.kubernetes.executor.volumes.persistentVolumeClaim.spark-local-dir-1.options.accessModes[0]=ReadWriteOnce \
    --conf spark.kubernetes.executor.volumes.persistentVolumeClaim.spark-local-dir-1.mount.path=/tmp \
    --conf spark.kubernetes.executor.volumes.persistentVolumeClaim.spark-local-dir-1.mount.readOnly=false \
    --conf spark.kubernetes.authenticate.executor.serviceAccountName=${SPARK_DRIVER_SERVICE_ACCOUNT} \
    --conf spark.kubernetes.executor.secretKeyRef.AWS_ACCESS_KEY_ID=thrift-spark-secret:aws-access-key-id \
    --conf spark.kubernetes.executor.secretKeyRef.AWS_SECRET_ACCESS_KEY=thrift-spark-secret:aws-secret-access-key \
    --conf spark.kubernetes.executor.secretKeyRef.METASTORE_URI=thrift-spark-secret:metastore-uri \
    --conf spark.kubernetes.executor.secretKeyRef.WAREHOUSE=thrift-spark-secret:warehouse 

