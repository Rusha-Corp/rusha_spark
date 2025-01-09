#!/bin/bash

set -e;

poetry run ansible-playbook playbooks/build.yml \
    --extra-vars "registry=europe-west1-docker.pkg.dev/owa-gemini/docker-registry" \
    --extra-vars "project_dir=$(pwd)" \
    -i hosts.ini -vv;

aws sts assume-role \
  --role-arn $AWS_ROLE_ARN \
  --role-session-name spark-thrift-server \
  --duration-seconds 900 \


# Install SBT