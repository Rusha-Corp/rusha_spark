name := "spark-iceberg-delta-unitycatalog"
version := "1.0"
scalaVersion := "2.13.17"
javacOptions ++= Seq("-source", "17", "-target", "17")

val nettyVersion = "4.2.17.Final"
val nettyModules = Seq(
  "netty-all",
  "netty-buffer",
  "netty-codec",
  "netty-codec-base",
  "netty-codec-compression",
  "netty-codec-dns",
  "netty-codec-http",
  "netty-codec-http2",
  "netty-codec-socks",
  "netty-common",
  "netty-handler",
  "netty-handler-proxy",
  "netty-resolver",
  "netty-resolver-dns",
  "netty-transport",
  "netty-transport-classes-epoll",
  "netty-transport-native-epoll",
  "netty-transport-native-unix-common"
)

dependencyOverrides ++= nettyModules.map("io.netty" % _ % nettyVersion) ++ Seq(
  "software.amazon.awssdk" % "bundle" % "2.57.10",
  "org.apache.derby" % "derby" % "10.17.1.0",
  "org.apache.derby" % "derbyshared" % "10.17.1.0",
  "org.apache.derby" % "derbytools" % "10.17.1.0"
)

libraryDependencies ++= Seq(
  "org.apache.spark" %% "spark-core" % "4.1.4" % Provided,
  "org.apache.spark" %% "spark-sql" % "4.1.4" % Provided,
  "org.apache.spark" %% "spark-hive" % "4.1.4" % Provided,
  "org.apache.spark" %% "spark-hadoop-cloud" % "4.1.4" % Provided,
  "org.apache.hadoop" % "hadoop-aws" % "3.4.2",
  ("io.netty" % "netty-all" % nettyVersion)
    .exclude("io.netty", "netty-codec-haproxy")
    .exclude("io.netty", "netty-codec-memcache")
    .exclude("io.netty", "netty-codec-mqtt")
    .exclude("io.netty", "netty-codec-redis")
    .exclude("io.netty", "netty-codec-smtp")
    .exclude("io.netty", "netty-codec-stomp")
    .exclude("io.netty", "netty-codec-xml")
    .exclude("io.netty", "netty-resolver-dns-classes-macos")
    .exclude("io.netty", "netty-resolver-dns-native-macos")
    .exclude("io.netty", "netty-transport-rxtx")
    .exclude("io.netty", "netty-transport-sctp")
    .exclude("io.netty", "netty-transport-udt")
    .exclude("io.netty", "netty-handler-ssl-ocsp"),
  "io.netty" % "netty-transport-native-epoll" % nettyVersion classifier "linux-x86_64",
  "org.apache.derby" % "derby" % "10.17.1.0",
  "org.apache.derby" % "derbytools" % "10.17.1.0",
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
