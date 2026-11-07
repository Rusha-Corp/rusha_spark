.PHONY: build release push up check audit validate help

IMAGE_REPO ?= $(shell grep "^DOCKER_REPO=" .env 2>/dev/null | cut -d'=' -f2 | tr -d '"')
ifeq ($(IMAGE_REPO),)
IMAGE_REPO = rusha-spark-4.1-base
endif
IMAGE_TAG ?= $(shell git rev-parse --short=7 HEAD)
TEST_IMAGE ?= $(IMAGE_REPO):$(IMAGE_TAG)-test

# Default target
help:
	@echo "Rusha Spark Environment Management"
	@echo ""
	@echo "Usage:"
	@echo "  make build         Build locally unless DOCKER_REGISTRY is configured"
	@echo "  make push          Legacy helper to push to DOCKER_REGISTRY"
	@echo "  make release       Run the legacy version release helper"
	@echo "  make up            Start local services via Docker Compose"
	@echo "  make check         Run quality and security checks"
	@echo "  make audit         Verify project standards"
	@echo "  make validate      Run the built image runtime smoke test"
	@echo "  Official GHCR publishing runs in CI after a green push to main."
	@echo ""

build:
	@./local/build.sh

push:
	@if [ -z "$$(grep "^DOCKER_REGISTRY=" .env 2>/dev/null | cut -d'=' -f2)" ] && [ -z "$$DOCKER_REGISTRY" ]; then \
		echo "Error: DOCKER_REGISTRY is not set in .env or environment."; \
		echo "This legacy target is intended for explicitly requested registry operations."; \
		exit 1; \
	fi
	@./local/build.sh

release:
	@if [ -n "$(VERSION)" ]; then \
		./scripts/release.sh $(VERSION); \
	elif [ -n "$(TYPE)" ]; then \
		./scripts/release.sh $(TYPE); \
	else \
		echo "Error: Neither VERSION nor TYPE (patch|minor|major) is set."; \
		echo "Usage: make release VERSION=v1.2.3  OR  make release TYPE=patch"; \
		exit 1; \
	fi

patch:
	@$(MAKE) release TYPE=patch

minor:
	@$(MAKE) release TYPE=minor

major:
	@$(MAKE) release TYPE=major

up:
	@docker compose --profile common up -d --build

check:
	@echo "--- Running Security & Quality Checks ---"
	@echo "[1/3] Scanning code/config files for hardcoded secret-like values..."
	@# Gitleaks is the secret scanner; this legacy heuristic skips protocol records and the required OIDC token permission.
	@! git ls-files -z | grep -zv '^\.contract-engineering/' | xargs -0 grep -iE "password|secret|token|key|private" | \
		grep -v ".gitignore" | \
		grep -v "poetry.lock" | \
		grep -v "README.md" | \
		grep -v "Makefile" | \
		grep -vE "\$${[A-Z0-9_]+}" | \
		grep -vE "AWS_[A-Z_]+" | \
		grep -vE "CATALOG_[A-Z_]+" | \
		grep -vE "POSTGRES_[A-Z_]+" | \
		grep -vE "MLFLOW_[A-Z_]+" | \
		grep -vE "apt-key|copyDependencies|password-stdin|secretKeyRef|GITHUB_TOKEN|id-token: write|gpg|keyring|keyserver|signing-key" || (echo "FAILED: Potential hardcoded secrets detected!" && exit 1)
	@echo "[2/3] Verifying documentation integrity..."
	@test -f README.md || (echo "FAILED: README.md missing" && exit 1)
	@if [ -f .env ]; then echo ".env found"; else echo "WARNING: .env file missing. Local builds will not push to registry."; fi
	@echo "[3/3] Checking script syntax..."
	@for script in scripts/*.sh scripts/ci/*.sh local/build.sh; do bash -n "$$script"; done
	@if grep -nE 'echo.*AWS_(ACCESS_KEY_ID|SECRET_ACCESS_KEY)' scripts/start_thrift_server.sh; then \
		echo "FAILED: Thrift entrypoint prints AWS credential values."; \
		exit 1; \
	fi
	@python3 -c 'import ast, pathlib; ast.parse(pathlib.Path("scripts/ci/check-runtime-jars.py").read_text())'
	@echo "SUCCESS: All checks passed."

audit:
	@echo "--- Verifying Registry-Agnostic Standards ---"
	@echo "Checking docker-compose.yml for hardcoded internal registry URIs..."
	@if grep -E "image: .*amazonaws.com" docker-compose.yml > /dev/null; then \
		echo "FAILED: Hardcoded ECR image found in docker-compose.yml. Use 'build: .' instead."; \
		exit 1; \
	fi
	@echo "SUCCESS: Project adheres to registry-agnostic standards."

validate:
	@echo "--- Validating Built Image Runtime ---"
	@echo "Validating image: $(IMAGE_REPO):$(IMAGE_TAG)"
	@docker build --platform linux/amd64 \
		--build-arg SPARK_BASE_IMAGE="$(IMAGE_REPO):$(IMAGE_TAG)" \
		--tag "$(TEST_IMAGE)" \
		--file Dockerfile.test .
	@docker run --rm "$(TEST_IMAGE)"
	@echo "SUCCESS: Image validation passed."