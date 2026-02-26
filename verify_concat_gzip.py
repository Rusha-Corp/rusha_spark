from pyspark.sql import SparkSession
import sys

def verify_concat_gzip(file_path):
    spark = SparkSession.builder \
        .appName("VerifyConcatGzip") \
        .getOrCreate()
    
    try:
        # Use sc.textFile which is more sensitive to GzipCodec limitations
        rdd = spark.sparkContext.textFile(file_path)
        count = rdd.count()
        print(f"Record count: {count}")
        
        if count == 5:
            print("SUCCESS: Read 5 records from concatenated gzip.")
        else:
            print(f"FAILURE: Read {count} records, expected 5.")
            sys.exit(1)
            
    finally:
        spark.stop()

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: verify_concat_gzip.py <file_path>")
        sys.exit(1)
    verify_concat_gzip(sys.argv[1])
