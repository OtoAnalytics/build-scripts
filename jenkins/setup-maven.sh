#!/usr/bin/env bash

# Versions the project based on the branch name
#
# Command Line Arguments:
#   directories to set versions within (optional, defaults to cwd)

set -e

CURRENT_VERSION=$(mvn -q  -Dexec.executable="echo" -Dexec.args='${project.version}' --non-recursive exec:exec|sed 's/-.*//')

# trim off 'origin/' from git branch
BRANCH_NAME=$(echo ${GIT_BRANCH} | sed 's/origin\///')

if [ "${BRANCH_NAME}" = "master" ]; then
  # create a release version by taking the leading version number and appending the build number
  NEW_VERSION=${CURRENT_VERSION}.${BUILD_NUMBER}
else
  # update maven version to be 1.0-<branchname>-SNAPSHOT
  NEW_VERSION=${CURRENT_VERSION}-${BRANCH_NAME}-SNAPSHOT
fi

# If directory arguments are passed in, run mvn versions:set in each of those directories
# Else run it in the current directory
if [ "${#@}" -eq 0 ]; then
  mvn --batch-mode versions:set -DgenerateBackupPoms=false -DnewVersion=${NEW_VERSION}
else
  for i in "$@"; do
    cd $i
    mvn --batch-mode versions:set -DgenerateBackupPoms=false -DnewVersion=${NEW_VERSION}
    cd ..
  done
fi
