# Spark Thrift Server Startup Script

This script is used to start the Spark Thrift Server on Kubernetes with various configurations and environment variables.

## Environment Variables

The following environment variables are used in the script:

- `SPARK_MASTER`: The URL of the Spark master.
- `SPARK_SQL_SERVER_PORT`: The port for the Spark SQL server (default: 10000).
- `SPARK_DRIVER_MEMORY`: Memory allocated for the Spark driver (default: 32g).
- `SPARK_EXECUTOR_MEMORY`: Memory allocated for Spark executors (default: 64g).
- `SPARK_EXECUTOR_CORES`: Number of cores for Spark executors (default: 8).
- `SPARK_WAREHOUSE_DIR`: Directory for Spark warehouse.
- `METASTORE_URIS`: URIs for the Hive metastore.
- `AWS_ACCESS_KEY_ID`: AWS access key ID.
- `AWS_SECRET_ACCESS_KEY`: AWS secret access key.
- `SPARK_HOME`: Path to the Spark home directory.
- `SPARK_LOG_DIR`: Directory for Spark logs (default: /tmp/spark-events).
- `SPARK_DRIVER_MAX_RESULT_SIZE`: Maximum result size for the Spark driver (default: 128g).
- `SPARK_EXECUTOR_MEMORY_OVERHEAD`: Memory overhead for Spark executors (default: 8g).
- `SPARK_DRIVER_HOST`: Host for the Spark driver.
- `SPARK_DRIVER_PORT`: Port for the Spark driver (default: 7077).
- `SPARK_UI_PORT`: Port for the Spark UI (default: 4040).
- `SPARK_DRIVER_BLOCK_MANAGER_PORT`: Port for the Spark driver block manager (default: 7078).
- `IMAGE`: Docker image for the Spark container.
- `NAMESPACE`: Kubernetes namespace.
- `SPARK_DRIVER_SERVICE_ACCOUNT`: Service account for the Spark driver.
- `SPARK_DRIVER_POD_NAME`: Pod name for the Spark driver.

## Script Steps

1. **Log Environment Variables**: The script logs the values of the environment variables for debugging purposes.
2. **Set Hadoop Client Options**: Sets the Hadoop client options for garbage collection and memory settings.
3. **Ensure Necessary Directories Exist**: Creates the necessary directories for Spark logs if they do not exist.
4. **Check Required Environment Variables**: Ensures that all required environment variables are set and assigns default values where applicable.
5. **Start Spark Thrift Server**: Uses `spark-submit` to start the Spark Thrift Server with various configurations.

## Spark Submit Configuration

The `spark-submit` command is configured with the following options:

- `--class org.apache.spark.sql.hive.thriftserver.HiveThriftServer2`: Specifies the main class for the Spark Thrift Server.
- `--master "k8s://https://${SPARK_MASTER}"`: Specifies the master URL for Kubernetes.
- `--deploy-mode client`: Specifies the deploy mode.
- Various `--conf` options to configure Spark settings, including:
    - Spark SQL warehouse directory.
    - Hive metastore URIs.
    - AWS credentials for S3 access.
    - Spark event log settings.
    - Memory and core settings for the driver and executors.
    - Kubernetes-specific configurations such as container image, namespace, and service account.
    - Dynamic allocation settings.
    - Speculation settings.
    - Network and timeout settings.

## Usage

To use this script, ensure that all required environment variables are set and then execute the script:

