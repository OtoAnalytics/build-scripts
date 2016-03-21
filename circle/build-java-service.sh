#!/usr/bin/env bash

# Builds the java project
#
# Non Circle Provided Input Variables:
#   MVN_ARGS: extra arguments to pass to maven
#   DOCKER_HOST: maven uses this to connect to the docker daemon, generally unix:///var/run/docker.sock

set -e

if [ -z "${MVN_ARGS}" ]; then
  mvn deploy 
else
  mvn deploy ${MVN_ARGS}
fi
