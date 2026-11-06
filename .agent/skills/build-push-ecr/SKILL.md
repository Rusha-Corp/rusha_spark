---
name: build-push-ecr
description: Legacy ECR-specific local build helper. Official Spark image publishing uses GHCR CI.
disable-model-invocation: true
---

# Legacy ECR Build Helper

This helper is retained for explicitly requested ECR operations. It is not the official Spark image release path. Do not run it or push to ECR unless the user explicitly asks for that external action.

- Legacy ECR registry: `217493348668.dkr.ecr.eu-west-2.amazonaws.com`
- Current image repository name: `rusha-spark-4.1-base`

For routine publication, `.github/workflows/ci.yml` builds, tests, scans, and publishes the image to GHCR after a green push to `main`. Local validation uses `make build` followed by `make validate`.