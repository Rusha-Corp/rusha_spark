---
name: build-push-ecr
description: Build and push the Spark image to the project ECR repo using local/build.sh and validate the result.
disable-model-invocation: true
---

# Build & Push ECR Image

## Inputs
- ECR registry: `217493348668.dkr.ecr.eu-west-2.amazonaws.com`
- Repository: `rusha-spark-3.5-base`

## Steps
1. Verify `.env` has:
   - `DOCKER_REGISTRY=217493348668.dkr.ecr.eu-west-2.amazonaws.com`
   - `DOCKER_REPO=rusha-spark-3.5-base`
2. Run `./local/build.sh` to build and push the image.
3. Run validators:
   - `make check`
   - `make validate`

## Success Criteria
- Build completes and image is pushed.
- Validators pass with no errors.
