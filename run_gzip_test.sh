#!/bin/bash
set -e

# Generate test data
python3 /opt/spark/generate_concat_data.py

# Run spark-submit to verify concatenated gzip
spark-submit /opt/spark/verify_concat_gzip.py concat_test.json.gz
