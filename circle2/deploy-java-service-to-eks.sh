#!/usr/bin/env bash

# Does a deploy to EKS, sets up tags & release notes in github, and notifies slack

set -e

export CURRENT_VERSION=$(mvn -q -Dexec.executable="echo" -Dexec.args='${project.version}' --non-recursive exec:exec)
TIMESTAMP=$(date +"%Y%m%d-%H%M%S")
export SPECIFIC_BRANCH=${TIMESTAMP}-${CIRCLE_BRANCH}-${CIRCLE_SHA1:0:7}

do-eks-deployment.sh ${SPECIFIC_BRANCH} ${EKS_ENVIRONMENT}

do-release-notes.sh

do-slack-notification.sh
