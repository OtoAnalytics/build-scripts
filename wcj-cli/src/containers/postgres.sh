#!/usr/bin/env bash

start_postgres() {
  POSTGRES_CONTAINER_NAME=$1
  POSTGRES_HOST=$CONTAINERS_HOST_NAME
  POSTGRES_DATABASE=${POSTGRES_DATABASE:-service}
  POSTGRES_USER=${POSTGRES_USER:-service}
  POSTGRES_PASSWORD=${POSTGRES_PASSWORD:-service}
  # TODO Get a random available port number here
  POSTGRES_PORT=${POSTGRES_PORT:-8432}
  POSTGRES_DOCKER_IMAGE=${POSTGRES_DOCKER_IMAGE:-"postgres:12-alpine"}

  exec_or_die docker run --name $POSTGRES_CONTAINER_NAME \
    -e "POSTGRES_PASSWORD=$POSTGRES_PASSWORD" \
    -e "POSTGRES_USER=$POSTGRES_USER" \
    -e "POSTGRES_DB=$POSTGRES_DATABASE" \
    -p "$POSTGRES_PORT:5432" \
    -d --rm \
    $POSTGRES_DOCKER_IMAGE

  docker_build_arg "DB_HOST" "$POSTGRES_HOST"
  docker_build_arg "DB_DATABASE" "$POSTGRES_DATABASE"
  docker_build_arg "DB_USER" "$POSTGRES_USER"
  docker_build_arg "DB_PASSWORD_CRYPT" "$POSTGRES_PASSWORD"
  docker_build_arg "DB_PORT" "$POSTGRES_PORT"
}
