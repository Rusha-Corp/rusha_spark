name := "spark-unity-catalog"
version := "1.0"
scalaVersion := "2.13.13"  // Use a Scala version compatible with Spark
javacOptions ++= Seq("-source", "17", "-target", "17")  // Java 17 compatibility

libraryDependencies ++= Seq(
    "org.apache.spark" %% "spark-core" % "3.5.3" % Provided,
    "org.apache.spark" %% "spark-sql" % "3.5.3" % Provided,
    "io.delta" %% "delta-spark" % "3.2.1",
    "org.apache.spark" %% "spark-hadoop-cloud" % "3.5.3",
)

assemblyMergeStrategy in assembly := {
    case PathList("META-INF", xs @ _*) => MergeStrategy.discard
    case x => MergeStrategy.first
}
