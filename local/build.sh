#!/bin/bash

set -e;

poetry run ansible-playbook playbooks/build.yml \
    --extra-vars "registry=europe-west1-docker.pkg.dev/owa-gemini/docker-registry" \
    --extra-vars "project_dir=$(pwd)" \
    -i hosts.ini -vv;

docker buildx build \
      --platform linux/amd64 \
      --build-arg BUILDKIT_INLINE_CACHE=1 \
      -t europe-west1-docker.pkg.dev/owa-gemini/docker-registry/rusha-spark-environment-3.5.3-scala2.12-java17-python3.12.0:3a42ada \
      . --push