# This Scala application can be run in several ways:

 1. Using sbt (Scala Build Tool):
 - Create a build.sbt file with required dependencies
 - Run using: sbt run

 2. Using spark-submit:
 spark-submit \
   --class App \
   --master yarn \
   --deploy-mode cluster \
   --conf spark.driver.cores=8 \
   --conf spark.driver.memory=32g \
   --conf spark.executor.cores=8 \
   --conf spark.executor.memory=32g \
   your-application.jar

 3. Required environment variables must be set:
 export AWS_ROLE_ARN=<role-arn>
 export AWS_DEFAULT_REGION=<region>
 export WAREHOUSE=<warehouse-location>
 export METASTORE_URI=<metastore-uri>
 export UNITY_URI=<unity-uri>
 export UNITY_TOKEN=<unity-token>
 export ICEBERG_REST_URI=<iceberg-rest-uri>

 4. Required dependencies:
 - Apache Spark
 - AWS SDK
 - Delta Lake
 - Apache Iceberg
 - Unity Catalog client libraries
