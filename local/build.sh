#!/bin/bash

set -e;

# Load environment variables if .env exists
if [ -f .env ]; then
    source .env
fi

IMAGE_NAME="${DOCKER_REPO:-rusha-spark-3.5.3-base}"
TAG=${1:-$(git rev-parse --short HEAD)}
REGISTRY="${DOCKER_REGISTRY}"

if [ -n "$REGISTRY" ]; then
    echo "Registry detected: $REGISTRY"
    
    # Optional: AWS ECR Login helper if registry looks like ECR
    if [[ "$REGISTRY" == *.amazonaws.com ]]; then
        echo "Detected AWS ECR registry. Attempting login..."
        AWS_REGION="${AWS_REGION:-${AWS_DEFAULT_REGION:-eu-west-2}}"
        aws ecr get-login-password --region "${AWS_REGION}" | docker login --username AWS --password-stdin "${REGISTRY}"
    fi

    echo "Building and pushing Spark base image to $REGISTRY..."
    docker buildx build \
          --platform linux/amd64 \
          --build-arg BUILDKIT_INLINE_CACHE=1 \
          -t "${REGISTRY}/${IMAGE_NAME}:${TAG}" \
          -t "${REGISTRY}/${IMAGE_NAME}:latest" \
          . --push
else
    echo "No DOCKER_REGISTRY set. Building image locally..."
    docker buildx build \
          --platform linux/amd64 \
          --build-arg BUILDKIT_INLINE_CACHE=1 \
          -t "${IMAGE_NAME}:${TAG}" \
          -t "${IMAGE_NAME}:latest" \
          .
    echo "Build complete. Image tagged as ${IMAGE_NAME}:latest"
fi