# Concatenated GZIP Support: Verification and Configuration Guide

This document explains how concatenated (multi-member) GZIP support was verified and how the environment is configured to ensure robust decompression in the Spark base image.

## 1. Hadoop Native Configuration

To support concatenated GZIP files, the environment must use the Hadoop Native Decompressor instead of falling back to the standard Java `GZIPInputStream`. The base image is configured with the following:

*   **Hadoop Version**: 3.3.6 (Native libraries and aligned JARs).
*   **JobConf Fix**: Added `hadoop-mapreduce-client-core`, `hadoop-mapreduce-client-common`, and `hadoop-mapreduce-client-jobclient` to ensure `org.apache.hadoop.mapred.JobConf` is available for Spark Context initialization.
*   **Library Path**: Native libraries (`.so` files) are located at `/opt/hadoop/lib/native/`.
*   **JNI Hook**: `hadoop-common-3.3.6.jar` is placed in `/opt/hadoop/lib/` to enable the `NativeCodeLoader` to bridge Java calls to the native C libraries.
*   **Environment Variables**:
    *   `LD_LIBRARY_PATH=/opt/hadoop/lib/native`
    *   `HADOOP_COMMON_LIB_NATIVE_DIR=/opt/hadoop/lib/native`
    *   `HADOOP_OPTS="-Djava.library.path=/opt/hadoop/lib/native"`

## 2. Multi-Member Test Strategy

Verification was performed using a three-phase approach to simulate real-world "dirty" concatenated GZIP streams.

### Phase A: Data Generation
We used a Python script (`generate_concat_data.py`) to create a multi-member GZIP file.
*   **Method**: Five individual JSON records were compressed into five separate GZIP members.
*   **Concatenation**: These members were combined into a single file (`cat member1.gz member2.gz ... > concat.gz`).
*   **Requirement**: A valid reader must not stop after the first `0x1f 0x8b` header but must continue reading until the actual end of the file.

### Phase B: PySpark Verification
We executed a PySpark script (`verify_concat_gzip.py`) using `sc.textFile()`. This method is the most sensitive as it relies directly on the Hadoop `GzipCodec`.

*   **Log Monitoring**: We verified that the following appeared in the Spark driver logs:
    *   `INFO ZlibFactory: Successfully loaded & initialized native-zlib library`
    *   `INFO CodecPool: Got brand-new decompressor [.gz]`
*   **Result**: The test passed only when the record count exactly matched the number of concatenated members (e.g., **Record count: 5**).

## 3. Developer Guidelines

For developers using this image as a base:

1.  **Use Hadoop-Compatible APIs**: Prefer `spark.read.text()`, `spark.read.json()`, or `sc.textFile()`. These automatically utilize the pre-configured `GzipCodec`.
2.  **Monitor Native Loading**: On startup, ensure `NativeCodeLoader` reports success. The image is pre-configured, so no manual property overrides (like `spark.hadoop.io.compression.codecs`) are typically required.
3.  **Local File Resilience**: Unlike standard Java readers that may fail on local concatenated files, this native setup provides the same resilience for `file://` schemes as it does for `s3a://` or `hdfs://`.

## 4. Verified Image
The latest verified image containing these fixes is:
**`217493348668.dkr.ecr.eu-west-2.amazonaws.com/rusha-spark-3.5-base:619063c`**
