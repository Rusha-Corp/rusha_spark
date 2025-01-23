# Spark Thrift Server Startup Script

This script starts the Spark Thrift Server on Kubernetes with various configurations and environment variables.

## Environment Variables

The script uses the following environment variables:

- `SPARK_MASTER`: URL of the Spark master.
- `SPARK_SQL_SERVER_PORT`: Port for the Spark SQL server (default: 10000).
- `SPARK_DRIVER_MEMORY`: Memory for the Spark driver (default: 32g).
- `SPARK_EXECUTOR_MEMORY`: Memory for Spark executors (default: 64g).
- `SPARK_EXECUTOR_CORES`: Cores for Spark executors (default: 8).
- `SPARK_WAREHOUSE_DIR`: Directory for Spark warehouse.
- `METASTORE_URIS`: URIs for the Hive metastore.
- `AWS_ACCESS_KEY_ID`: AWS access key ID.
- `AWS_SECRET_ACCESS_KEY`: AWS secret access key.
- `SPARK_HOME`: Path to the Spark home directory.
- `SPARK_LOG_DIR`: Directory for Spark logs (default: /tmp/spark-events).
- `SPARK_DRIVER_MAX_RESULT_SIZE`: Max result size for the Spark driver (default: 128g).
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

1. **Log Environment Variables**: Logs the environment variables for debugging.
2. **Set Hadoop Client Options**: Configures Hadoop client options for garbage collection and memory.
3. **Ensure Necessary Directories Exist**: Creates directories for Spark logs if they don't exist.
4. **Check Required Environment Variables**: Ensures all required environment variables are set and assigns default values if needed.
5. **Start Spark Thrift Server**: Uses `spark-submit` to start the Spark Thrift Server with various configurations.

## Spark Submit Configuration

The `spark-submit` command is configured with:

- `--class org.apache.spark.sql.hive.thriftserver.HiveThriftServer2`: Main class for the Spark Thrift Server.
- `--master "k8s://https://${SPARK_MASTER}"`: Master URL for Kubernetes.
- `--deploy-mode client`: Deploy mode.
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

Ensure all required environment variables are set, then execute the script:

```bash
./start_thrift_server_k8s.sh
```

## Additional Services

### Hue

Hue is a web-based interface for interacting with Hadoop and Spark.

- **Image**: `gethue/hue:latest`
- **Hostname**: `hue`
- **Depends on**: `spark-thrift-server`
- **Volumes**: `./conf:/usr/share/hue/desktop/conf`
- **Networks**: `spark-container-network`
- **Restart Policy**: `unless-stopped`

### MLflow

MLflow is an open-source platform for managing the end-to-end machine learning lifecycle.

- **Build Context**: `.`
- **Dockerfile**: `Dockerfile`
- **Environment Variables**:
  - `AWS_ACCESS_KEY_ID`
  - `AWS_SECRET_ACCESS_KEY`
  - `AWS_DEFAULT_REGION`
  - `AWS_SESSION_TOKEN`
- **Command**: `mlflow server --backend-store-uri postgresql://postgres:password@postgres:5432/postgres --default-artifact-root ${ARTIFACTS_ROOT} --host 0.0.0.0 --port 5000`
- **Volumes**:
  - `./tmp:/tmp`
  - `./mlflow:/mlflow`
- **Networks**: `spark-container-network`
- **Restart Policy**: `always`

### Iceberg REST

Iceberg REST provides a REST interface for Apache Iceberg.

- **Image**: `apache/iceberg-rest-fixture`
- **Container Name**: `iceberg-rest`
- **Networks**: `spark-container-network`
- **Restart Policy**: `always`
- **Environment Variables**:
  - `AWS_ACCESS_KEY_ID`
  - `AWS_SECRET_ACCESS_KEY`
  - `AWS_REGION`
  - `CATALOG_WAREHOUSE`
  - `CATALOG_IO__IMPL`
  - `CATALOG_S3_ENDPOINT`
  - `CATALOG_JDBC__IMPL`
  - `CATALOG_JDBC__URL`
  - `CATALOG_JDBC__USER`
  - `CATALOG_JDBC__PASSWORD`

### Ingress

Ingress is used to expose HTTP and HTTPS routes from outside the Kubernetes cluster to services within the cluster.

- **Image**: `nginx:latest`
- **Ports**:
  - `80:80`
  - `443:443`
- **Volumes**:
  - `./nginx.conf:/etc/nginx/nginx.conf`
  - `./certs:/etc/letsencrypt`
- **Networks**: `spark-container-network`
- **Restart Policy**: `always`

## Network Configuration

All services are connected to the `spark-container-network` network, which is external to the Docker Compose setup.
