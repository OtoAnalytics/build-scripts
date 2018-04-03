#!/usr/bin/env bash

# Caches the images specified in docker_deps.yml in ~/docker_cache

set -e

mkdir -p ~/docker_cache
while IFS=: read DOCKERNAME DOCKERPATH; do
  docker save ${DOCKERPATH} > ~/docker_cache/${DOCKERNAME}.tar
done < docker_deps.yml