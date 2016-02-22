#!/usr/bin/env bash

# Does a deploy to ECS, sets up tags & release notes in github, and notifies slack
#
# Non Circle Provided Input Variables:
#   REPO_ROOT: URL to the docker repository organization (eg quay.io/womply)
#   SPECIFIC_BRANCH: docker image tag, generally ${TIMESTAMP}-${CIRCLE_BRANCH}-${CIRCLE_SHA1}
#   ECS_PROD_CLUSTER: cluster to deploy the master branch to
#   ECS_PREPROD_CLUSTER: cluster to deploy the develop branch to
#   GITHUB_AUTH_TOKEN: auth token to hit the github API with
#   SLACK_NOTIFICATION_WEBHOOK: URL to a slack notification webhook

set -e

export CURRENT_VERSION=$(mvn -q  -Dexec.executable="echo" -Dexec.args='${project.version}' --non-recursive exec:exec)

do-ecs-deployment.sh

do-release-notes.sh

do-slack-notification.sh