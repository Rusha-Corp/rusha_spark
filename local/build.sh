#!/bin/bash

set -e;

poetry run ansible-playbook playbooks/build.yml \
    --extra-vars "registry=europe-west1-docker.pkg.dev/owa-gemini/docker-registry" \
    --extra-vars "project_dir=$(pwd)" \
    -i hosts.ini -vv;




# Install SBT