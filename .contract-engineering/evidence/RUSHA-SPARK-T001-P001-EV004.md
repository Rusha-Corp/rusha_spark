# RUSHA-SPARK-T001-P001-EV004 — Java 21 dependency remediation and final local gate

Date: 2026-11-06
Repository: `Rusha-Corp/rusha_spark`
Worktree: `/tmp/rusha-spark-ghcr`
Branch: `feat/spark-4.1.4-ghcr-ci`
Status: Local build, runtime smoke, critical Trivy gate, and protocol-record checks pass; branch remains unpushed pending final commit/history verification and hosted CI.

## Remediation selected under DEC002

- Build and runtime use `eclipse-temurin:21-jdk-jammy` pinned to index digest `sha256:4b1a74fbffbe6b4e7b6f0171a472478282fb463790a51edf10e465d578f22b69`.
- Spark remains 4.1.4, Scala 2.13.17, Python 3.12.16, Hadoop 3.4.2, and all approved connector versions.
- SBT overrides Netty to `4.2.17.Final`, AWS SDK v2 bundle to `2.57.10`, and Derby components to `10.17.1.0`.
- Dependency updates alone left two fixable CRITICAL Trivy records for Netty metadata in the Spark Connect client jar and YARN shuffle plugin. Searches of the OWA and lens-ETL source worktrees found no Spark Connect client or YARN workload references. The image retains `spark-kubernetes_2.13-4.1.4.jar`; its `KubernetesClientApplication` class is loaded by the smoke test. Under DEC002, the Connect client/JDBC jars and shell and the YARN shuffle jar were excluded.
- The AWS SDK/Hadoop compatibility smoke initializes `S3AFileSystem` with anonymous credentials and a loopback-only endpoint. It makes no S3 request and reads no ambient credentials.

## Local validation

- Built the `linux/amd64` image with `sbt compile`; the in-image jar guard accepted Hadoop 3.4.2, AWS SDK v2 2.57.10, Netty 4.2.17.Final, and Derby 10.17.1.0. The Spark archive SHA-512 matched the existing pin.
- The default Apache Archive endpoint reset/timed out from this environment. The local build used `SPARK_DOWNLOAD_BASE=https://dlcdn.apache.org/spark`; the official CDN served the same Spark 4.1.4 archive and its SHA-512 verification passed. The Dockerfile default remains the Apache Archive.
- Final base image ID: `sha256:58845d02e5dfe43ddfc118f2af8e823bfe3bda43a1512a58cf9dba12abaed369`.
- The Dockerfile.test smoke container exited 0. It verified Java 21, Spark/PySpark 4.1.4, Python 3.12.16, Py4J 0.10.9.9, dependency versions, Kubernetes submission class loading, absence of the excluded artifacts, S3A initialization, Hadoop native/zlib loading, and local Iceberg/Delta writes and reads. The fresh Iceberg warehouse emitted two initial `version-hint.text` not-found diagnostics; all write/read assertions passed.
- Trivy 0.70.0 scanned the final base image with the CI settings `--scanners vuln,license --vuln-type os,library --ignore-unfixed --severity CRITICAL --exit-code 1`; it exited 0 with no CRITICAL findings. License scanning remains inventory-only under the approved policy.
- `make check`, `make audit`, `poetry check --lock`, Ruff check/format for `scripts/ci/check-runtime-jars.py`, Hadolint 2.12.0, ShellCheck 0.10.0 on the changed Thrift and smoke-test scripts, and the Gitleaks 8.30.1 working-tree scan passed. The unchanged `local/build.sh` passed ShellCheck before this remediation (EV003). Poetry emitted the existing metadata deprecation warnings; `make check` noted the expected absence of local `.env`.
- `actionlint` 1.7.12 had passed on the unchanged CI workflow before this remediation.
- The locked Contract Engineering v3.1.0 enforced packet/scope validator passed with the complete changed-path set; tracker validation passed with one active row and zero archive rows; `render-tracker.py --check` passed.

## Remaining gates and limits

- Re-run Gitleaks history scanning and the locked Contract Engineering validators/render check against the final committed head.
- The image has not been pushed and no PR has been opened. Hosted PR CI, including its independent image build and Trivy scan, remains required.
- Independent reviewer acceptance of DEC001 is still required before merge.
- No live S3 request, Kubernetes cluster test, GHCR publication, package visibility/access change, secret change, ECR/AWS infrastructure change, or deployment was performed.
- The Trivy gate covers fixable CRITICAL findings and ignores unfixed findings; higher-severity-policy disposition and license inventory remain governed by DEC001 and its required independent review.
