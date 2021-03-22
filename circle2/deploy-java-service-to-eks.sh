#!/usr/bin/env bash

# Does a deploy to EKS, sets up tags & release notes in github, and notifies slack

set -e

export CURRENT_VERSION=$(mvn -q -Dexec.executable="echo" -Dexec.args='${project.version}' --non-recursive exec:exec)

do-eks-deployment.sh ${CIRCLE_BRANCH} ${EKS_ENVIRONMENT}
do-release-notes.sh
do-slack-notification.sh
