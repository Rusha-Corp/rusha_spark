name := "spark-iceberg-delta-unitycatalog"
version := "1.0"
scalaVersion := "2.13.17"
javacOptions ++= Seq("-source", "17", "-target", "17")

libraryDependencies ++= Seq(
  "org.apache.spark" %% "spark-core" % "4.1.4" % Provided,
  "org.apache.spark" %% "spark-sql" % "4.1.4" % Provided,
  "org.apache.spark" %% "spark-hive" % "4.1.4" % Provided,
  "org.apache.spark" %% "spark-hadoop-cloud" % "4.1.4" % Provided,
  "org.apache.hadoop" % "hadoop-aws" % "3.4.2",
  "io.delta" % "delta-spark_4.1_2.13" % "4.4.1",
  "io.unitycatalog" %% "unitycatalog-spark" % "0.4.1",
  "org.apache.iceberg" % "iceberg-spark-runtime-4.1_2.13" % "1.12.0",
  "org.apache.iceberg" % "iceberg-aws-bundle" % "1.12.0",
  "org.projectnessie.nessie-integrations" %% "nessie-spark-extensions-4.1" % "0.110.0"
).map(
  _.exclude("org.slf4j", "slf4j-api")
    .exclude("org.slf4j", "slf4j-log4j12")
    .exclude("org.apache.logging.log4j", "log4j-to-slf4j")
    .exclude("org.apache.logging.log4j", "log4j-slf4j-impl")
    .exclude("ch.qos.logback", "logback-classic")
)

assembly / assemblyMergeStrategy := {
  case PathList("META-INF", xs @ _*) => MergeStrategy.discard
  case x => MergeStrategy.first
}

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

Compile / compile := (Compile / compile).dependsOn(copyDependencies).value
