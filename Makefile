.PHONY: build release push up check audit validate help

# Default target
help:
	@echo "Rusha Spark Environment Management"
	@echo ""
	@echo "Usage:"
	@echo "  make build         Build the Spark base image (local only if DOCKER_REGISTRY is not set)"
	@echo "  make push          Build and push the image to the configured registry"
	@echo "  make release       Create a new versioned release (usage: make release VERSION=v1.0.0)"
	@echo "  make up            Start local services via Docker Compose"
	@echo "  make check         Run quality and security checks"
	@echo "  make audit         Verify project standards (registry-agnostic configs, etc.)"
	@echo "  make validate      Verify the built image runtime (Spark, scripts, JARs)"
	@echo ""

build:
	@./local/build.sh

push:
	@if [ -z "$$(grep "^DOCKER_REGISTRY=" .env 2>/dev/null | cut -d'=' -f2)" ] && [ -z "$$DOCKER_REGISTRY" ]; then \
		echo "Error: DOCKER_REGISTRY is not set in .env or environment."; \
		echo "This target is intended for internal use to push to the registry."; \
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
	@echo "[1/3] Scanning for hardcoded secrets in tracked files..."
	@# Filter out common false positives and environment variable placeholders
	@! git ls-files | xargs grep -iE "password|secret|token|key|private" | \
		grep -v ".gitignore" | \
		grep -v "poetry.lock" | \
		grep -v "README.md" | \
		grep -v "Makefile" | \
		grep -vE "\$${[A-Z0-9_]+}" | \
		grep -vE "AWS_[A-Z_]+" | \
		grep -vE "CATALOG_[A-Z_]+" | \
		grep -vE "POSTGRES_[A-Z_]+" | \
		grep -vE "MLFLOW_[A-Z_]+" | \
		grep -vE "apt-key|copyDependencies|password-stdin|secretKeyRef" || (echo "FAILED: Potential hardcoded secrets detected!" && exit 1)
	@echo "[2/3] Verifying documentation integrity..."
	@test -f README.md || (echo "FAILED: README.md missing" && exit 1)
	@if [ -f .env ]; then echo ".env found"; else echo "WARNING: .env file missing. Local builds will not push to registry."; fi
	@echo "[3/3] Checking build script syntax..."
	@bash -n local/build.sh
	@bash -n scripts/release.sh
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
	@$(eval IMAGE_REPO := $(shell grep "^DOCKER_REPO=" .env 2>/dev/null | cut -d'=' -f2 | tr -d '\"'))
	@$(eval IMAGE_REPO := $(if $(IMAGE_REPO),$(IMAGE_REPO),rusha-spark-3.5.3-base))
	@$(eval TAG := $(shell git rev-parse --short HEAD))
	@echo "Validating image: $(IMAGE_REPO):$(TAG)"
	@docker run --rm $(IMAGE_REPO):$(TAG) bash -c "\
		echo '[1/4] Checking Spark version...'; \
		spark-submit --version && \
		echo '[2/4] Checking for entrypoint scripts...'; \
		ls -la /start_thrift_server.sh /start-spark.sh && \
		echo '[3/4] Checking for core Spark extensions...'; \
		ls -la /opt/spark/jars/iceberg-spark-runtime-3.5_*.jar && \
		ls -la /opt/spark/jars/nessie-spark-extensions-3.5_*.jar && \
		ls -la /opt/spark/jars/unitycatalog-spark_*.jar && \
		echo '[4/4] Checking Python version...'; \
		python3 --version"
	@echo "SUCCESS: Image validation passed."

