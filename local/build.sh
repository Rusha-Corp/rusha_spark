#!/bin/bash

set -e;
docker buildx build \
    --platform linux/amd64 \
    --build-arg BUILDKIT_INLINE_CACHE=1 \
    -t registry.bitkubeops.com/spark-master:latest . --push;

