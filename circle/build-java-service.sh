#!/usr/bin/env bash

# Polls coveralls for code coverage statistics, and fails the build if coverage is less than 80% or has
# decreased by more than 3%
#
# Non Circle Provided Input Variables:
#   COVERALLS_REPO_TOKEN: coveralls API token for the current repository
#   DOCKER_HOST: maven uses this to connect to the docker daemon, generally unix:///var/run/docker.sock

set -e

if [ -z "${MVN_ARGS}" ]; then
  mvn deploy 
else
  mvn deploy ${MVN_ARGS}
fi

set +e

if [ "${CIRCLE_BRANCH}" != "master" -a "${CIRCLE_BRANCH}" != "develop" ]; then
  STATUS=255
  TRIES=0
  while [ $STATUS -eq 255 -a $TRIES -lt 10 ]; do
    curl -s "https://coveralls.io/builds/${CIRCLE_SHA1}.json?repo_token=${COVERALLS_REPO_TOKEN}" 2>/dev/null | parse-coveralls-status.py
    STATUS=$?
    TRIES=$(($TRIES+1))
    if [ $STATUS -eq 255 -a $TRIES -lt 10 ]; then
      echo "Coveralls is still processing, sleeping and retrying after $TRIES retries"
      sleep 10
    fi
  done
  if [ $STATUS -eq 255 ]; then
    echo "Giving up on coveralls after $TRIES retries"
    exit 0
  fi
  exit $STATUS
fi
