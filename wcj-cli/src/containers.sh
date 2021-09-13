#!/usr/bin/env bash

. "$WCJ_DIR/src/common.sh"

# Need this because only builds require the Docker hostname
CONTAINERS_HOST_NAME="localhost"

usage() {
  echo "usage: wcj containers <start|stop> [-p PROJECT_DIR]"
}

start_containers() {
  parse_common_opts "$@"
  require_wcj_project

  for container_type in ${CONTAINERS//,/ }; do
    container_name="$PROJECT_NAME-$container_type"

    # Kill the container if it is already running
    [[ "$(docker ps -a | grep $container_name)" ]] && stop_container $container_name

    echo "Starting $container_name... "
    . $WCJ_DIR/src/containers/$container_type.sh

    "start_$container_type" "$container_name"
    if [ $? -ne 0 ]; then
      echo "Error $? while trying to start $container_name!"
      exit 1
    fi
  done
}

stop_containers() {
  parse_common_opts "$@"
  require_wcj_project

  for container_type in ${CONTAINERS//,/ }; do
    container_name="$PROJECT_NAME-$container_type"
    stop_container $container_name
  done
}

stop_container() {
  echo "Stopping $1..."
  exec_or_die docker rm -f $1
}

docker_build_arg() {
  DOCKER_BUILD_ARGS="${DOCKER_BUILD_ARGS} --build-arg ${1}=${2}"
  OUTPUT_ENV_VARS="${OUTPUT_ENV_VARS}${1}=${2}\n"
}

containers() {
  case "$1" in
    start)
      start_containers "${@:2}"

      echo "Container(s) Started"
      echo -e "$OUTPUT_ENV_VARS"
      ;;
    stop)
      stop_containers "${@:2}"
      ;;
    *)
      echo "Must specify start or stop argument"
      usage
      exit 1
      ;;
  esac
}
