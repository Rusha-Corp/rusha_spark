# Dockerfile Documentation

## Purpose
This Dockerfile is designed to create a customized Spark container with specified environment variables and dependencies. It's intended for use in data engineering and analytics workflows.

### Base Image
```dockerfile
FROM spark:3.5.0-scala2.12-java17-ubuntu
```
The Dockerfile is based on the Spark image with version 3.5.0, Scala 2.12, and Java 17 on an Ubuntu base.

### Environment Variables
Several environment variables are defined to configure Spark and its dependencies.

- **Spark Configuration**
  - `SPARK_EXECUTOR_MEMORY`: Executor memory for Spark.
  - `SPARK_EXECUTOR_CORES`: Number of executor cores.
  - `SPARK_HOME`: Spark installation directory.
  - `SPARK_VERSION`: Spark version.
  - ... (and more)

- **AWS and Hadoop Configuration**
  - `HADOOP_VERSION`: Version of Hadoop.
  - `AWS_SDK_VERSION`: Version of AWS SDK.
  
- **Spark NLP Configuration**
  - `SPARK_NLP_VERSION`: Version of Spark NLP.

- **Python and User Configuration**
  - `PYTHON_VERSION`: Python version.
  - `USER`: User for Spark execution.
  - `SSH_PRIVATE_KEY` and `SSH_PUBLIC_KEY`: SSH keys for user.

### Dockerfile Steps

#### 1. Set Spark Environment Variables
Spark environment variables are set based on the specified arguments.

#### 2. Install Dependencies and Tools
Install necessary dependencies and tools for the Spark container.

#### 3. Install AWS CLI
Install the AWS CLI to enable interaction with AWS services.

#### 4. Copy JAR Files
Download and copy various JAR files required for Spark, Hadoop, AWS SDK, Spark NLP, TensorFlow, and Delta.

#### 5. Remove Unnecessary Files
Remove temporary and unnecessary files after copying JARs.

#### 6. Set Up Working Directory and Logs
Set up the working directory for Spark and create log files.

#### 7. Set Up User and Permissions
Create a non-root user with specified permissions for Spark execution.

#### 8. Copy SSH Keys and Configure
Copy SSH keys for secure communication and configure SSH settings.

#### 9. Copy Python Project Files and Install Dependencies
Copy Python project files (pyproject.toml, poetry.lock) and install dependencies using Poetry.

### Entrypoint and CMD
```dockerfile
COPY start-spark.sh /start-spark.sh
CMD ["/bin/bash", "/start-spark.sh"]
```
The entry point is a script named `start-spark.sh` that controls the Spark workload (master, worker, or submit) based on the environment variable `SPARK_WORKLOAD`. The CMD instruction specifies the default command to execute when the container starts.

# Start Script Documentation

## Purpose
The `start-spark.sh` script is responsible for launching Spark in different modes depending on the specified workload: master, worker, or submit.

### Script Steps

1. **Source Spark Environment**
   ```bash
   . "/opt/spark/bin/load-spark-env.sh"
   ```
   Source the Spark environment to set up necessary configurations.

2. **Launch Spark Master**
   ```bash
   if [ "$SPARK_WORKLOAD" == "master" ]; then
      export SPARK_MASTER_HOST=`hostname`
      cd /opt/spark/bin && ./spark-class org.apache.spark.deploy.master.Master --ip $SPARK_MASTER_HOST --port $SPARK_MASTER_PORT --webui-port $SPARK_MASTER_WEBUI_PORT >> $SPARK_MASTER_LOG
   ```

   If the workload is specified as "master," set up and start the Spark master.

3. **Launch Spark Worker**
   ```bash
   elif [ "$SPARK_WORKLOAD" == "worker" ]; then
      cd /opt/spark/bin && ./spark-class org.apache.spark.deploy.worker.Worker --webui-port $SPARK_WORKER_WEBUI_PORT $SPARK_MASTER >> $SPARK_WORKER_LOG
   ```

   If the workload is specified as "worker," set up and start the Spark worker.

4. **Handle Spark Submission (Placeholder)**
   ```bash
   elif [ "$SPARK_WORKLOAD" == "submit" ]; then
      echo "SPARK SUBMIT"
   ```

   Placeholder for handling Spark submission (not implemented).

5. **Handle Undefined Workload Type**
   ```bash
   else
      echo "Undefined Workload Type $SPARK_WORKLOAD, must specify: master, worker, submit"
   ```

   Display a message if an undefined workload type is specified.

### Usage
To use this Docker image, run the container with the desired workload:

- For Spark Master:
  ```bash
  docker run -e SPARK_WORKLOAD=master <image_name>
  ```

- For Spark Worker:
  ```bash
  docker run -e SPARK_WORKLOAD=worker <image_name>
  ```

- For Spark Submission (Placeholder):
  ```bash
  docker run -e SPARK_WORKLOAD=submit <image_name>
  ```

### Note
Ensure that the necessary environment variables, such as `SPARK_MASTER_PORT` and `SPARK_WORKER_PORT`, are correctly configured for the intended Spark cluster setup. Adjustments may be needed based on specific requirements and configurations.