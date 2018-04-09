#!/usr/bin/env bash

# Does a deploy to ECS, sets up tags & release notes in github, and notifies slack
#
# Non Circle Provided Input Variables:
#   GITHUB_AUTH_TOKEN: auth token to hit the github API with
#   SLACK_NOTIFICATION_WEBHOOK: URL to a slack notification webhook

set -e

export CURRENT_VERSION=$(mvn -q -Dexec.executable="echo" -Dexec.args='${project.version}' --non-recursive exec:exec)
TIMESTAMP=$(date +"%Y%m%d-%H%M%S")
export SPECIFIC_BRANCH="N/A"

do-release-notes.sh

do-slack-notification.sh
