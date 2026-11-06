# RUSHA-SPARK-T001-P001-EV003 — Local validation and security checks

Date: 2026-11-06
Repository: `Rusha-Corp/rusha_spark`
Worktree: `/tmp/rusha-spark-ghcr`
Branch: `feat/spark-4.1.4-ghcr-ci`
Status: The original local Trivy gate failed; remediation under DEC002 now passes locally. The branch remains unpushed pending final commit/history verification and hosted CI.

## Passed locally

- `make build && make validate`: final `Dockerfile` build completed with `sbt compile`; the runtime smoke wrapper passed version, jar, S3A, native Hadoop, Unity Catalog, Iceberg, and Delta checks. Local image ID: `sha256:e3f2e2b3ba410534f7b38d0b0ff1029006becbfc46abf7d5730145ec3416b36d`.
- `make check && make audit && poetry check --lock && git diff --check`: passed. Poetry emitted existing metadata deprecation warnings; `make check` reported the absent `.env` file, which is expected for local-only builds.
- `actionlint` 1.7.12: passed on `.github/workflows/ci.yml`.
- `hadolint` 2.12.0 with the workflow's `failure-threshold: error`: passed on `Dockerfile` and `Dockerfile.test` with no diagnostics.
- `shellcheck` 0.10.0 with `--severity=warning` on the changed shell scripts: passed.
- A broader ShellCheck attempt found existing findings in unchanged scripts, including SC1128 in `scripts/start-spark.sh`. To keep this packet in scope, CI lints changed shell scripts; `make check` still syntax-checks every shell script.
- Gitleaks 8.30.1 redacted working-tree scan: passed with the Trivy finding summary recorded. The history scan passed after the implementation commit; rerun after this rework evidence commit and any remediation commit before push.
- The locked Contract Engineering v3.1.0 preflight, enforced contract-record validator, and tracker validator passed for the complete changed-path set.
- Manual security review of changed code and workflow controls found no code-level exploit; the separate Trivy image scan below identified upstream dependency vulnerabilities.

## Original blocking security finding (resolved)

- Trivy 0.70.0, installed from the official Linux release archive after verifying SHA-256 `8b4376d5d6befe5c24d503f10ff136d9e0c49f9127a4279fd110b727929a5aa9`, scanned local image `sha256:e3f2e2b3ba410534f7b38d0b0ff1029006becbfc46abf7d5730145ec3416b36d` with `--scanners vuln,license --vuln-type os,library --ignore-unfixed --severity CRITICAL --exit-code 1`. The scan returned exit 1 with 5 CRITICAL findings, all reported with fixed versions.
- `CVE-2026-75595` (`io.netty:netty-handler`) appears in four artifacts: Hadoop AWS SDK bundle `2.29.52` (Netty `4.1.115.Final`), Spark Connect client `4.1.4`, the standalone Netty `4.2.7.Final` jar, and Spark YARN shuffle `4.1.4`. Trivy lists `4.2.17.Final` or `4.1.137.Final` as fixed versions.
- `CVE-2022-46337` appears in Derby `10.16.1.1`; Trivy lists `10.16.1.2` as a fixed version.
- These CRITICAL findings were not covered by DEC001, which only excepts HIGH and unfixed findings, and blocked any push or PR. The approved remediation and passing final local scan are recorded in EV004.

## Compatibility investigation

- The upstream Spark 4.1.4 POM pins Netty `4.2.7.Final`, AWS SDK v2 `2.29.52`, and Derby `10.16.1.1` (`https://github.com/apache/spark/blob/v4.1.4/pom.xml`). Changing these versions would alter the approved dependency closure.
- The built image's AWS SDK bundle, Spark Connect client, and Spark YARN shuffle jars contain Netty Maven metadata but no `io/netty/*.class` entries. The standalone Netty handler jar contains Netty classes. Trivy still reports the older Netty coordinates found in those jars' metadata.
- Maven Central has no Derby `10.16.1.2` artifact; its metadata lists `10.16.1.1` as the Java 17 line. Apache Derby's official release page says Derby 10.17 requires Java 21, and 10.17.1.0 includes the CVE-2022-46337 LDAP fix. Derby is retired, with no further releases planned (`https://db.apache.org/derby/derby_downloads.html`, `https://db.apache.org/derby/releases/release-10_17_1_0.cgi`).
- Therefore, no verified fix preserves both the original Java 17 runtime and dependency closure. The user approved retaining Spark 4.1.4 while changing to Java 21 and overriding affected dependencies; optional Connect/YARN artifact removal is approved only if necessary. See DEC002. This section records the pre-remediation state; the implementation and final scan are in EV004.

## Superseded build attempt

An earlier final-image attempt using `sbt assembly` exhausted the builder's
1 GiB Java heap. The assembled jar is not copied into the runtime image.
The Dockerfile uses `sbt compile`, which resolved and compiled the dependency
set, populated `target/lib`, built the final image, and passed `make validate`.

## Pending after remediation and before merge

- Hosted PR CI, including the Trivy vulnerability/license scan and the hosted image build.
- Independent reviewer acceptance of DEC001 before merge.
- The approved Trivy policy blocks fixable CRITICAL vulnerabilities; HIGH and unfixed findings are covered by the scoped exception in DEC001. License results are informational only.
- No GHCR publication, remote digest, provenance attestation, or package access change has occurred.
- CodeQL and a separate GitHub dependency-review job are not part of the approved CI design; this limitation remains for security-gate review.
