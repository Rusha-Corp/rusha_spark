#!/usr/bin/env bash
set -euo pipefail

: "${SPARK_HOME:?SPARK_HOME must be set}"
: "${HADOOP_HOME:?HADOOP_HOME must be set}"
: "${SPARK_VERSION:?SPARK_VERSION must be set}"
: "${SCALA_VERSION:?SCALA_VERSION must be set}"
: "${HADOOP_NATIVE_VERSION:?HADOOP_NATIVE_VERSION must be set}"
: "${HADOOP_AWS_SDK_V2_VERSION:?HADOOP_AWS_SDK_V2_VERSION must be set}"
: "${NETTY_VERSION:?NETTY_VERSION must be set}"
: "${DERBY_VERSION:?DERBY_VERSION must be set}"

spark_version_output=$(spark-submit --version 2>&1)
grep -Fq "version ${SPARK_VERSION}" <<<"$spark_version_output"
grep -Fq "Scala version ${SCALA_VERSION}" <<<"$spark_version_output"

java_version=$(java -version 2>&1 | awk -F '"' '/version/ { print $2; exit }')
[[ "$java_version" == 21.* ]]

python3 - <<'PY'
import sys
import pyspark
import py4j

assert sys.version_info[:3] == (3, 12, 16), sys.version
assert pyspark.__version__ == "4.1.4", pyspark.__version__
assert py4j.__version__ == "0.10.9.9", py4j.__version__
print(
    f"Python {sys.version_info.major}.{sys.version_info.minor}.{sys.version_info.micro}; "
    f"PySpark {pyspark.__version__}; Py4J {py4j.__version__}"
)
PY

python3 /usr/local/bin/check-runtime-jars.py \
  --spark-jars "$SPARK_HOME/jars" \
  --expected-hadoop "$HADOOP_NATIVE_VERSION" \
  --expected-aws-sdk-v2 "$HADOOP_AWS_SDK_V2_VERSION" \
  --expected-netty "$NETTY_VERSION" \
  --expected-derby "$DERBY_VERSION"

require_one_jar() {
  local pattern="$1"
  local -a matches
  mapfile -t matches < <(find "$SPARK_HOME/jars" -maxdepth 1 -type f -name "$pattern" -print)
  if [[ ${#matches[@]} -ne 1 ]]; then
    printf 'Expected one jar matching %s, found %s\n' "$pattern" "${#matches[@]}" >&2
    printf '%s\n' "${matches[@]}" >&2
    return 1
  fi
}

require_one_jar 'iceberg-spark-runtime-4.1_2.13-1.12.0.jar'
require_one_jar 'spark-kubernetes_2.13-4.1.4.jar'
require_one_jar 'iceberg-aws-bundle-1.12.0.jar'
require_one_jar 'delta-spark_4.1_2.13-4.4.1.jar'
require_one_jar 'nessie-spark-extensions-4.1_2.13-0.110.0.jar'
require_one_jar 'unitycatalog-spark_2.13-0.4.1.jar'
test ! -e "$SPARK_HOME/jars/connect-repl/spark-connect-client-jvm_2.13-${SPARK_VERSION}.jar"
test ! -e "$SPARK_HOME/jars/connect-repl/spark-connect-client-jdbc_2.13-${SPARK_VERSION}.jar"
test ! -e "$SPARK_HOME/bin/spark-connect-shell"
test ! -e "$SPARK_HOME/yarn/spark-${SPARK_VERSION}-yarn-shuffle.jar"

test -f "$HADOOP_HOME/lib/native/libhadoop.so"

python3 - <<'PY'
from pathlib import Path
import tempfile

from pyspark.sql import SparkSession

extensions = ",".join(
    [
        "org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions",
        "org.projectnessie.spark.extensions.NessieSparkSessionExtensions",
        "io.delta.sql.DeltaSparkSessionExtension",
    ]
)

with tempfile.TemporaryDirectory(prefix="spark-4.1-smoke-") as temp_dir:
    warehouse = Path(temp_dir, "warehouse").as_uri()
    delta_path = Path(temp_dir, "delta")

    spark = (
        SparkSession.builder.master("local[2]")
        .appName("rusha-spark-4.1-smoke")
        .config("spark.ui.enabled", "false")
        .config("spark.driver.host", "127.0.0.1")
        .config("spark.driver.bindAddress", "127.0.0.1")
        .config("spark.sql.extensions", extensions)
        .config(
            "spark.sql.catalog.spark_catalog",
            "org.apache.spark.sql.delta.catalog.DeltaCatalog",
        )
        .config("spark.sql.catalog.smoke", "org.apache.iceberg.spark.SparkCatalog")
        .config("spark.sql.catalog.smoke.type", "hadoop")
        .config("spark.sql.catalog.smoke.warehouse", warehouse)
        .getOrCreate()
    )

    try:
        spark.sparkContext.setLogLevel("WARN")
        jvm = spark._jvm

        for class_name in (
            "org.apache.hadoop.fs.s3a.S3AFileSystem",
            "io.unitycatalog.spark.UCSingleCatalog",
            "org.apache.spark.deploy.k8s.submit.KubernetesClientApplication",
        ):
            jvm.java.lang.Class.forName(class_name)

        s3a_conf = jvm.org.apache.hadoop.conf.Configuration(
            spark._jsc.hadoopConfiguration()
        )
        s3a_conf.set(
            "fs.s3a.aws.credentials.provider",
            "org.apache.hadoop.fs.s3a.AnonymousAWSCredentialsProvider",
        )
        s3a_conf.set("fs.s3a.endpoint", "http://127.0.0.1:9000")
        s3a_conf.set("fs.s3a.path.style.access", "true")
        s3a_fs = jvm.org.apache.hadoop.fs.FileSystem.get(
            jvm.java.net.URI.create("s3a://compatibility-check/"),
            s3a_conf,
        )
        s3a_fs.close()

        native_loaded = jvm.org.apache.hadoop.util.NativeCodeLoader.isNativeCodeLoaded()
        zlib_loaded = jvm.org.apache.hadoop.io.compress.zlib.ZlibFactory.isNativeZlibLoaded(
            spark._jsc.hadoopConfiguration()
        )
        assert native_loaded, "Hadoop native library failed to load"
        assert zlib_loaded, "Hadoop native zlib failed to load"

        frame = spark.createDataFrame([(1, "alpha"), (2, "beta")], "id INT, value STRING")
        spark.sql("CREATE NAMESPACE IF NOT EXISTS smoke.db")
        frame.writeTo("smoke.db.iceberg_table").createOrReplace()
        assert spark.table("smoke.db.iceberg_table").count() == 2

        frame.write.format("delta").mode("overwrite").save(str(delta_path))
        assert spark.read.format("delta").load(str(delta_path)).count() == 2
    finally:
        spark.stop()

print("Spark 4.1.4, Nessie, S3A, Hadoop native, Unity Catalog, Iceberg, and Delta smoke checks passed.")
PY
