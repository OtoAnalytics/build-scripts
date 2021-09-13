#!/usr/bin/env bash

. "$WCJ_DIR/src/build.sh"

usage() {
  echo "usage: wcj info <image-name> [-p PROJECT_DIR]"
}

image_name() {
  parse_opts "$@"
  require_wcj_project

  QUIET=1
  git_and_docker_vars

  echo "$DOCKER_IMAGE"
}

info() {
  case "$1" in
    image-name)
      image_name "${@:2}"
    ;;
  *)
    usage
    exit 1
    ;;
  esac
}

