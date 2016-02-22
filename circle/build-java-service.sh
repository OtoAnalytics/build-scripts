#!/usr/bin/env bash

# Polls coveralls for code coverage statistics, and fails the build if coverage is less than 80% or has
# decreased by more than 3%
#
# Non Circle Provided Input Variables:
#   COVERALLS_REPO_TOKEN: coveralls API token for the current repository
#   DOCKER_HOST: maven uses this to connect to the docker daemon, generally unix:///var/run/docker.sock

set -e

mvn deploy

set +e

if [ "${CIRCLE_BRANCH}" != "master" -a "${CIRCLE_BRANCH}" != "develop" ]; then
  STATUS=255
  TRIES=0
  while [ $STATUS -eq 255 -a $TRIES -lt 10 ]; do
    curl -s "https://coveralls.io/builds/${CIRCLE_SHA1}.json?repo_token=${COVERALLS_REPO_TOKEN}" 2>/dev/null | parse-coveralls-status.py
    STATUS=$?
    TRIES=$(($TRIES+1))
    if [ $STATUS -eq 255 ]; then
      echo $STATUS
      echo $TRIES
      sleep 10
    fi
  done && exit $STATUS
fi