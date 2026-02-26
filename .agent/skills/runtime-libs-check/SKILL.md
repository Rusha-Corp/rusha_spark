---
name: runtime-libs-check
description: Validate Spark runtime jars and bundled libraries in the image.
disable-model-invocation: true
---

# Runtime Libraries Check

## Steps
1. Verify Spark version:
   - `spark-submit --version`
2. Confirm required jars exist in `/opt/spark/jars`:
   - `ls -la /opt/spark/jars/iceberg-spark-runtime-3.5_*.jar`
   - `ls -la /opt/spark/jars/nessie-spark-extensions-3.5_*.jar`
   - `ls -la /opt/spark/jars/unitycatalog-spark_*.jar`

## Success Criteria
- Spark reports version 3.5.8.
- All required jars are present in `/opt/spark/jars`.
