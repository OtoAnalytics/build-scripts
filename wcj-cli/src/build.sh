#!/usr/bin/env bash

. "$WCJ_DIR/src/containers.sh"

# Running inside a Docker container so we have to use this
# host to reference the other contianers
CONTAINERS_HOST_NAME="localhost"

DOCKER_HOST_IP=`ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1' | head -1`

usage() {
  echo "usage: wcj build [-t TEST_ARTIFACTS_DEST] [-p PROJECT_DIR]"
}

# Parse command line options
parse_opts() {
  while getopts ":p:t:" opt; do
    case ${opt} in
      p )
        PROJECT_DIR=$OPTARG
        ;;
      t )
        TEST_ARTIFACTS_DEST=$OPTARG
        ;;
      \? )
        echo "Invalid option: -$OPTARG" 1>&2
        usage
        exit 1
        ;;
      : )
        echo "Invalid option: -$OPTARG requires an argument" 1>&2
        usage
        exit 1
        ;;
    esac
  done
}

set_ci_env_vars() {
  DOCKER_BUILD_ARGS="${DOCKER_BUILD_ARGS} --build-arg CIRCLE_BRANCH=${CIRCLE_BRANCH}"
  DOCKER_BUILD_ARGS="${DOCKER_BUILD_ARGS} --build-arg CIRCLE_BUILD_NUM=${CIRCLE_BUILD_NUM}"
}

build_docker_image() {
  echo "Building Docker Image $1"

  if [[ ! -z "$2" ]]; then
    OPTS="--target $2"
  fi

  exec_or_die docker build $OPTS \
    --pull \
    --network=host \
    --rm=false \
    --build-arg AWS_ACCESS_KEY_ID="$AWS_ACCESS_KEY_ID" \
    --build-arg AWS_SECRET_ACCESS_KEY="$AWS_SECRET_ACCESS_KEY" \
    --build-arg CIRCLE_BRANCH="$CIRCLE_BRANCH" \
    --build-arg CIRCLE_BUILD_NUM="$CIRCLE_BUILD_NUM" \
    ${DOCKER_BUILD_ARGS} \
    --tag $1 \
    $PROJECT_DIR
}

build_docker_image_build_stage() {
  BUILD_IMAGE="${PROJECT_NAME}-build"
  build_docker_image "$BUILD_IMAGE" "build"
}

build_docker_image_runtime_stage() {
  build_docker_image "$DOCKER_IMAGE"
}

copy_test_artifacts() {
  [ -n "$TEST_ARTIFACTS_DEST" ] || return

  echo "Exporting Test Artifacts to ${TEST_ARTIFACTS_DEST}"

  ARTIFACT_CONTAINER_NAME=$PROJECT_NAME-artifacts
  exec_or_die_with_output docker run --rm --name $ARTIFACT_CONTAINER_NAME $BUILD_IMAGE pwd
  CONTAINER_PWD="$OUTPUT"

  exec_or_die_with_output "docker run --rm --name $ARTIFACT_CONTAINER_NAME $BUILD_IMAGE find . -type d -name target | sed -r 's|/[^/]+$||' | sed 's/^\.\///g' | sort | uniq"
  MODULES_WITH_TARGET_DIRS="$OUTPUT"

  exec_or_die docker create --rm --name $ARTIFACT_CONTAINER_NAME $BUILD_IMAGE
  mkdir -p $TEST_ARTIFACTS_DEST
  while IFS= read -r dir; do
    mkdir -p $TEST_ARTIFACTS_DEST/$dir
    exec_optional docker cp "$ARTIFACT_CONTAINER_NAME:$CONTAINER_PWD/$dir/target/surefire-reports/junitreports" $TEST_ARTIFACTS_DEST/$dir
  done <<< "$MODULES_WITH_TARGET_DIRS"
  exec_or_die docker rm -f $ARTIFACT_CONTAINER_NAME
}

build() {
  parse_opts $@

  require_var AWS_ACCESS_KEY_ID
  require_var AWS_SECRET_ACCESS_KEY
  require_wcj_project

  start_containers
  set_ci_env_vars

  build_docker_image_build_stage || exit $?
  copy_test_artifacts

  if [ "$PROJECT_TYPE" == "service" ]; then
    build_docker_image_runtime_stage
  fi

  stop_containers

  exit 0
}
