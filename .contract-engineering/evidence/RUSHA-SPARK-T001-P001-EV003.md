# RUSHA-SPARK-T001-P001-EV003 — Local validation and security checks

Date: 2026-11-06
Repository: `Rusha-Corp/rusha_spark`
Worktree: `/tmp/rusha-spark-ghcr`
Branch: `feat/spark-4.1.4-ghcr-ci`
Status: In progress, hosted checks pending

## Passed locally

- `make build && make validate`: final `Dockerfile` build completed with `sbt compile`; the runtime smoke wrapper passed version, jar, S3A, native Hadoop, Unity Catalog, Iceberg, and Delta checks. Local image ID: `sha256:e3f2e2b3ba410534f7b38d0b0ff1029006becbfc46abf7d5730145ec3416b36d`.
- `make check && make audit && poetry check --lock && git diff --check`: passed. Poetry emitted existing metadata deprecation warnings; `make check` reported the absent `.env` file, which is expected for local-only builds.
- `actionlint` 1.7.12: passed on `.github/workflows/ci.yml`.
- `hadolint` 2.12.0 with the workflow's `failure-threshold: error`: passed on `Dockerfile` and `Dockerfile.test` with no diagnostics.
- `shellcheck` 0.10.0 with `--severity=warning` on the changed shell scripts: passed.
- A broader ShellCheck attempt found existing findings in unchanged scripts, including SC1128 in `scripts/start-spark.sh`. To keep this packet in scope, CI lints changed shell scripts; `make check` still syntax-checks every shell script.
- Gitleaks 8.30.1 redacted working-tree scan: passed on the current worktree, including the decision and evidence records. The history scan passed for the committed base; rerun it after the implementation commit before push.
- The locked Contract Engineering v3.1.0 preflight, enforced contract-record validator, and tracker validator passed for the complete changed-path set.
- Manual security review of the complete changed-file set: no high-confidence exploitable finding identified.

## Superseded build attempt

An earlier final-image attempt using `sbt assembly` exhausted the builder's
1 GiB Java heap. The assembled jar is not copied into the runtime image.
The Dockerfile uses `sbt compile`, which resolved and compiled the dependency
set, populated `target/lib`, built the final image, and passed `make validate`.

## Pending before merge

- Hosted PR CI, including the Trivy vulnerability/license scan and the hosted image build.
- Independent reviewer acceptance of DEC001 before merge.
- Re-run Gitleaks history scan after the implementation commit is created.
- The approved Trivy policy blocks fixable CRITICAL vulnerabilities; HIGH and unfixed findings are covered by the scoped exception in DEC001. License results are informational only.
- No GHCR publication, remote digest, provenance attestation, or package access change has occurred.
- CodeQL and a separate GitHub dependency-review job are not part of the approved CI design; this limitation remains for security-gate review.
