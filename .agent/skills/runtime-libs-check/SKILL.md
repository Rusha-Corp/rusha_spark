---
name: runtime-libs-check
description: Validate Spark runtime jars and bundled libraries in the image.
disable-model-invocation: true
---

# Runtime Libraries Check

After building the base image, run the production-equivalent smoke image:

```bash
make build
make validate
```

The smoke test verifies Spark 4.1.4, Scala 2.13.17, Java 21, Python 3.12.16,
PySpark 4.1.4, and Py4J 0.10.9.9. It checks Hadoop 3.4.2, AWS SDK v2 2.57.10,
Netty 4.2.17.Final, Derby 10.17.1.0, Iceberg 1.12.0, Nessie 0.110.0,
Delta 4.4.1, and Unity Catalog 0.4.1.

The test confirms the Spark Kubernetes submission client remains available
while the unused Connect client jars/shell and YARN shuffle plugin are absent.
It initializes S3A with anonymous credentials and a loopback-only endpoint,
loads the Unity Catalog and Kubernetes submission classes, verifies Hadoop
native decompression, then exercises local Iceberg and Delta writes and reads.
It does not contact S3 or a Kubernetes cluster.

The image build rejects duplicate or version-mismatched Hadoop and AWS SDK
jars and checks that all bundled Netty and Derby jars use their approved
versions.