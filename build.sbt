name := "spark-iceberg-delta-unitycatalog"
version := "1.0"
scalaVersion := "2.12.19"  // Use a Scala version compatible with Spark
javacOptions ++= Seq("-source", "17", "-target", "17")  // Java 17 compatibility

libraryDependencies ++= Seq(
  "org.apache.spark" %% "spark-core" % "3.5.8" % Provided,
  "org.apache.spark" %% "spark-sql" % "3.5.8" % Provided,
  "org.apache.spark" %% "spark-hive" % "3.5.8" % Provided,
  "io.delta" %% "delta-spark" % "3.3.0",
  "org.apache.spark" %% "spark-hadoop-cloud" % "3.5.8" exclude("org.apache.hadoop", "hadoop-client-api") exclude("org.apache.hadoop", "hadoop-client-runtime"),
  "org.apache.hadoop" % "hadoop-aws" % "3.3.6",
  "org.apache.hadoop" % "hadoop-common" % "3.3.6",
  "org.apache.hadoop" % "hadoop-client-api" % "3.3.6",
  "org.apache.hadoop" % "hadoop-client-runtime" % "3.3.6",
  "com.amazonaws" % "aws-java-sdk-bundle" % "1.12.367",
  "io.unitycatalog" %% "unitycatalog-spark" % "0.2.1",
  "org.apache.iceberg" %% "iceberg-spark-runtime-3.5" % "1.10.1",
  "org.apache.iceberg" % "iceberg-aws" % "1.10.1" % "runtime",
  "org.apache.iceberg" % "iceberg-aws-bundle" % "1.10.1",
  "org.projectnessie.nessie-integrations" %% "nessie-spark-extensions-3.5" % "0.105.6"
).map(
  _.exclude("org.slf4j", "slf4j-api") // Exclude SLF4J API
  .exclude("org.slf4j", "slf4j-log4j12") // Exclude SLF4J Log4j binding
  .exclude("org.apache.logging.log4j", "log4j-to-slf4j") // Exclude Log4j to SLF4J adapter
  .exclude("org.apache.logging.log4j", "log4j-slf4j-impl") // Exclude Log4j SLF4J implementation
  .exclude("ch.qos.logback", "logback-classic") // Exclude Logback
)

assembly / assemblyMergeStrategy := {
  case PathList("META-INF", xs @ _*) => MergeStrategy.discard
  case x => MergeStrategy.first
}

// Task to copy dependencies to the target directory
val copyDependencies = taskKey[Unit]("Copy dependencies to target directory")

copyDependencies := {
    val updateReport = update.value
    val targetDir = target.value / "lib"
    IO.createDirectory(targetDir)
    val jars = updateReport.select(configurationFilter("compile"))
    jars.foreach { jar =>
        IO.copyFile(jar, targetDir / jar.getName)
    }
}

// Ensure the copyDependencies task runs after compile
Compile / compile := (Compile / compile).dependsOn(copyDependencies).value
