import gzip
import os

def create_test_data(file_path):
    # Multiple gzip members concatenated
    with open(file_path, 'wb') as f:
        for i in range(5):
            with gzip.GzipFile(fileobj=f, mode='wb') as gz:
                gz.write(f'{{"id": {i}, "data": "record_{i}"}}\n'.encode('utf-8'))

if __name__ == "__main__":
    create_test_data("concat_test.json.gz")
    print("Created concat_test.json.gz")
