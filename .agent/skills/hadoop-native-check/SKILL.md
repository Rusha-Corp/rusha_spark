---
name: hadoop-native-check
description: Verify Hadoop native libraries are installed and discoverable.
disable-model-invocation: true
---

# Hadoop Native Library Check

The runtime image includes Hadoop 3.4.2 native libraries under `/opt/hadoop/lib/native`; it does not include the full Hadoop command-line distribution.

Run the image smoke test:

```bash
docker build \
  --build-arg SPARK_BASE_IMAGE=rusha-spark-4.1-base:latest \
  --tag rusha-spark-4.1-base-test:local \
  --file Dockerfile.test .
docker run --rm rusha-spark-4.1-base-test:local
```

The test verifies `libhadoop.so` exists, `NativeCodeLoader` and native zlib load in the JVM, and Spark can read and write local Iceberg and Delta data. `HADOOP_NATIVE_VERSION` must match the Hadoop client jars bundled with Spark.