#!/usr/bin/env bash

DOCKER_IMAGE_TAG=${1:-'latest'}
DOCKER_REGISTERY='quay.io/womply'

echo " - Pushing $REPO_NAME:$DOCKER_IMAGE_TAG to $DOCKER_REGISTERY"
echo $DOCKER_PASS | docker login --username $DOCKER_USER --password-stdin quay.io
docker build --build-arg GEMFURY_DEPLOY_TOKEN -t $DOCKER_REGISTERY/$REPO_NAME:$DOCKER_IMAGE_TAG .
docker push $DOCKER_REGISTERY/$REPO_NAME:$DOCKER_IMAGE_TAG
