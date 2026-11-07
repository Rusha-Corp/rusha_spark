# RUSHA-SPARK-T001-P001-EV005 — Hosted CI install failure

Date: 2026-11-06
Repository: `Rusha-Corp/rusha_spark`
Worktree: `/tmp/rusha-spark-ghcr`
Branch: `feat/spark-4.1.4-ghcr-ci`
Status: PR #1 remains open and unmerged. The workflow install path is corrected and local gates passed; the correction has not yet been pushed and hosted validation is pending.

## Failure

- GitHub Actions run `42288587320` failed in the `Install actionlint and Gitleaks` step at 2026-11-06T20:28:30Z.
- The workflow invoked `go install github.com/gitleaks/gitleaks/v8@v8.30.1`, but that module declares its path as `github.com/zricethezav/gitleaks/v8`.
- The quality job stopped before actionlint, Hadolint, ShellCheck, Gitleaks, and repository checks. The dependent image build and GHCR publish jobs were skipped.
- Pre-push checks scanned the repository with Gitleaks but did not execute the exact Go installation command used by CI. This locally runnable step was missed.

## Remediation

- The host has no Go installation. Ran the exact corrected `go install` command and `gitleaks version` in an isolated official `golang:1.26.10-bookworm` container; both exited successfully.
- Installed actionlint 1.7.12 with the exact workflow Go command in an isolated container and linted the corrected workflow; it passed.
- `make check`, `make audit`, Gitleaks working-tree scan, enforced Contract Engineering validation, tracker validation, generated projection check, and `git diff --check` passed.
- After correction commit `0dd2993`, Gitleaks scanned all 181 commits and the working tree without leaks; the enforced Contract Engineering validator, tracker validator, and generated projection check passed again.
- The actionlint, Gitleaks, ShellCheck, and Hadolint workflow sections not affected by the module-path line are unchanged; Hadolint and ShellCheck had passed locally before this correction (EV004).
- Push the correction and require the full hosted quality and image-test jobs to pass before merge.
- Keep PR #1 open. Do not merge or publish an image until hosted checks pass and the independent DEC001 reviewer accepts the scoped exception.

## Limits

- No image was published, no package access or visibility was changed, and no secret, AWS infrastructure, cluster, or deployment operation was performed.
- This evidence contains summarized check output only; it excludes credentials and raw logs.
