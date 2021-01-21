#!/usr/bin/env bash

start_redis() {
  REDIS_CONTAINER_NAME=$1
  REDIS_HOST=$CONTAINERS_HOST_NAME
  REDIS_PORT=${REDIS_PORT:-6379}
  REDIS_CONTAINER_PORT=6379
  REDIS_DOCKER_IMAGE="redis:5.0.3-alpine3.8"

  exec_or_die docker run --name $REDIS_CONTAINER_NAME \
    -d -p $REDIS_PORT:$REDIS_CONTAINER_PORT \
    $REDIS_DOCKER_IMAGE

  docker_build_arg "REDIS_HOST" "$REDIS_HOST"
  docker_build_arg "REDIS_PORT" "$REDIS_PORT"
}
