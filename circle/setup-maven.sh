#!/usr/bin/env bash

# Sets up maven settings.xml and versions the project based on the branch name
#
# Non Circle Provided Input Variables:
#   MVN_SETTINGS_XML: contents of ~/.m2/settings.xml
#
# Command Line Arguments:
#   directories to set versions within (optional, defaults to cwd)

set -e

echo $MVN_SETTINGS_XML > ~/.m2/settings.xml
cp ~/build-scripts/circle/simplelogger.properties ${M2_HOME}/conf/logging/simplelogger.properties

CURRENT_VERSION=$(mvn -q  -Dexec.executable="echo" -Dexec.args='${project.version}' --non-recursive exec:exec|sed 's/-.*//')
if [ "${CIRCLE_BRANCH}" = "master" ]; then
  # create a release version by taking the leading version number and appending the build number
  NEW_VERSION=${CURRENT_VERSION}.${CIRCLE_BUILD_NUM}
else
  # update maven version to be 1.0-<branchname>-SNAPSHOT
  NEW_VERSION=${CURRENT_VERSION}-${CIRCLE_BRANCH}-SNAPSHOT
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
