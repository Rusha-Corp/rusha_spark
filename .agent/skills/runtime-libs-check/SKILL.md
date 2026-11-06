---
name: runtime-libs-check
description: Validate Spark runtime jars and bundled libraries in the image.
disable-model-invocation: true
---

# Runtime Libraries Check

Run the production-equivalent smoke image after building the base image:

```bash
docker build \
  --build-arg SPARK_BASE_IMAGE=rusha-spark-4.1-base:latest \
  --tag rusha-spark-4.1-base-test:local \
  --file Dockerfile.test .
docker run --rm rusha-spark-4.1-base-test:local
```

The test validates Spark 4.1.4, Scala 2.13.17, PySpark 4.1.4, and the required Hadoop 3.4.2, Iceberg 1.12.0, Nessie 0.110.0, Delta 4.4.1, and Unity Catalog 0.4.1 jars. It also loads the Nessie and S3A classes and verifies Hadoop native decompression before exercising local Iceberg and Delta writes and reads.

The image build separately rejects duplicate or version-mismatched Hadoop and AWS SDK jars.