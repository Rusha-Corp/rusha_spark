# RUSHA-SPARK-T001-P001-EV001 — Baseline and design gates

Date: 2026-11-06
Repository: `Rusha-Corp/rusha_spark`
Base revision: `3f3271c9ef98793c3365011b108abc2edced114e`
Worktree: `/tmp/rusha-spark-ghcr`
Branch: `feat/spark-4.1.4-ghcr-ci`
Approved design: `/home/vscode/.factory/specs/2026-11-06-spark-4-1-base-on-ghcr-ghcr-only-owa-ci-and-lens-etl-migration-prs.md`

## Baseline

- Worktree was clean before packet records were added.
- Existing versions were Spark/PySpark 3.5.8, Hadoop/native 3.3.6, Scala 2.12.19, Python 3.12.12, Delta 3.3.0, Iceberg 1.10.1, Nessie 0.105.6, and Unity Catalog 0.2.1.
- The host has Docker Buildx and Poetry 2.5.1. Java, SBT, Go, and ShellCheck are not installed on the host; image and Scala verification will run in Docker.
- `make check` and `make audit` passed before implementation. The repository has no tracked test directory.
- `make validate` was not run at baseline because no current base image was built and `Dockerfile.test` refers to four absent assets: `test-data.json.gz`, `generate_concat_data.py`, `verify_concat_gzip.py`, and `run_gzip_test.sh`.
- Baseline line counts: Dockerfile 115; Dockerfile.test 10; build.sbt 53; Makefile 101; README.md 114; pyproject.toml 19; poetry.lock 3,730; local/build.sh 39; playbooks/build.yml 33. `poetry.lock` is retained as a generated lockfile despite exceeding 500 lines.
- Existing runtime validation and documentation still refer to Spark 3.5, and image defaults include `rusha-spark-3.5.3-base`.
- Docker's configured credential helper fails when querying Docker Hub metadata. `DOCKER_CONFIG=/tmp/owa-docker-config-ghcr-push` is an isolated empty-config workaround; no credentials were read or changed.

## Approved version and artifact research

The user-approved spec selects Spark 4.1.4, Scala 2.13.17, PySpark/Python 3.12.16, Hadoop 3.4.2, Iceberg 1.12.0, Nessie 0.110.0, Delta 4.4.1, and Unity Catalog 0.4.1. Spark 4.1.4 and Hadoop 3.4.2 source metadata and Maven Central POMs were read. Apache Spark and Hadoop archive SHA-512 values and Python 3.12.16 source SHA-256 are available for build-time verification. The Temurin 17 base index digest was resolved to `sha256:057a0daec60e87c96571bf5c9c7792065bcb19e804d584cd37d4144038a35717`.

Direct connector POMs resolve from Maven Central. Iceberg and Unity Catalog POMs declare Apache-2.0. The approved spec remains authoritative for the exact dependency matrix; dependency resolution and image scanning are still required.

## Protocol preflight

- The protocol source is Contract-Engineering v3.1.0, content commit `d9649f62cc20f0561b2eb7a8084eacedb4032365`.
- The signed annotated tag points to an attestation commit whose parent is that content commit. The v3.1.0 tag signature cryptographically verified against the public key in the protocol repository and matched fingerprint `038022B4EDF5F704B38DF6C7BE1DF7FA3C3BC996`; the local GPG trust level is undefined.
- All six installed governed skills and their reference files match the locked source hashes.
- The release attestation's transparency field is `PENDING_HOSTED_VALIDATION`; this is recorded as a limitation, not represented as a completed transparency check.

## Security design

Threat model: `.contract-engineering/threat-models/RUSHA-SPARK-T001-P001.yaml`.

Primary controls are SHA-pinned GitHub Actions, a digest-pinned Java base, checksummed source archives, dependency/version locks, read-only pull-request jobs, main-only package-write publishing, secret scanning, image vulnerability/license scanning, OCI source/provenance metadata, and remote digest equality checks. No ECR, Kubernetes, secrets, package visibility, or cluster rollout changes are authorized.

## Baseline commands

```text
make check        PASS
make audit        PASS
make validate     NOT RUN; no target image and legacy test assets absent
```

No Spark image build, GHCR write, PR, merge, ECR operation, or cluster operation has occurred.
