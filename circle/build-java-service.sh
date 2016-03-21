#!/usr/bin/env bash

# Builds the java project
#
# Non Circle Provided Input Variables:
#   MVN_ARGS: extra arguments to pass to maven
#   DOCKER_HOST: maven uses this to connect to the docker daemon, generally unix:///var/run/docker.sock
#   COVERALLS_REPO_TOKEN: coveralls API token for the current repository, used by maven coveralls plugin

set -e

if [ -z "${MVN_ARGS}" ]; then
  mvn deploy 
else
  mvn deploy ${MVN_ARGS}
fi
