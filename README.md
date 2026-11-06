# Rusha Spark 4.1.4 Base

This repository builds the `ghcr.io/rusha-corp/rusha-spark-4.1-base` image with Apache Spark 4.1.4 and its supported runtime libraries.

## Runtime versions

- Spark and PySpark 4.1.4
- Scala 2.13.17
- Java 17
- Python 3.12.16
- Hadoop client and native libraries 3.4.2
- Iceberg 1.12.0
- Nessie 0.110.0
- Delta Lake 4.4.1
- Unity Catalog 0.4.1

The image includes the Spark SQL integrations, Hadoop S3A support, and native Hadoop decompression libraries.

## Image publishing

`.github/workflows/ci.yml` runs quality checks, builds and smoke-tests the image, then scans it for critical vulnerabilities and licenses.

- Pull requests and manual workflow runs validate the image but do not publish it.
- A push to `main` publishes to GHCR only after all checks pass.
- CI publishes both the seven-character source commit tag and `4.1.4`, adds a GitHub artifact provenance attestation, and verifies that both tags resolve to the build digest.
- The package must be public or grant `packages: read` access to consumers such as lens-ETL.

Published image:
```text
ghcr.io/rusha-corp/rusha-spark-4.1-base:4.1.4
```

## Local development

Requirements: Docker with Buildx, Poetry 2.x, and Git.

Build locally, then run the runtime checks:
```bash
make build
make validate
```

`make validate` builds `Dockerfile.test` from the local image and runs `scripts/ci/smoke-test.sh`. The smoke test checks runtime versions and required jars, loads the Nessie, S3A, native Hadoop, and Unity Catalog classes, and writes and reads Iceberg and Delta data locally.

`DOCKER_REPO` can override the local image name. `DOCKER_REGISTRY` is supported by the legacy local helper for explicitly requested registry operations; it is not the official publishing path.

## Legacy release helper

`scripts/release.sh` and the Makefile release targets are a separate legacy workflow and are not used by GHCR CI. This change does not alter their behavior. Do not use them to publish the managed GHCR image.

## Services

The image supports Spark services such as the Thrift Server, MLflow integrations, and Iceberg REST. Service orchestration remains separate from image publication.

## Security

- Do not commit secrets or `.env` files.
- CI runs Gitleaks over repository history and scans the built image with Trivy.
- PySpark and Py4J come from the SHA-512-verified Spark distribution; Python dependency versions are pinned in `poetry.lock`.
