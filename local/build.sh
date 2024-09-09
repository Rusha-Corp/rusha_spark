#!/bin/bash

set -e;
docker buildx build \
    --platform linux/amd64,linux/arm64 \
    --build-arg BUILDKIT_INLINE_CACHE=1 \
    -t europe-west1-docker.pkg.dev/owa-gemini/docker-registry/spark-master:v2 . --push;



poetry run ansible-playbook playbooks/build.yml \
    --extra-vars "europe-west1-docker.pkg.dev/owa-gemini/docker-registry" \
    --extra-vars "project_dir=$(pwd)" \
