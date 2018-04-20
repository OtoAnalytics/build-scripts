#!/usr/bin/env bash

DOCKER_IMAGE_TAG=${1:-'latest'}
ENVIRONMENT_INSTANCE=${2:-'default'}
ECS_CLUSTER=${3:-'default'}
ECS_SERVICE=${4:-'default'}
LAST_COMMIT_MESSAGE=$(git log -1 --pretty='%s')
LAST_COMMIT=$(git rev-parse HEAD)
FEATURE="${LAST_COMMIT_MESSAGE##*/}"

HEALTH_CHECK_URL="http://${ECS_SERVICE_NUMBER}.${ENVIRONMENT_INSTANCE}/admin/health"
SERVICES_HEALTH_CHECK_URL="http://${ECS_SERVICE_NUMBER}.${ENVIRONMENT_INSTANCE}/admin/services_health"

function post () {
  SLACK_MESSAGE="$1"
  curl -X POST --data-urlencode "payload={\"channel\": \"$SLACK_CHANNEL\",\"username\": \"CIRCLE_BOT\", \"text\": \"$SLACK_MESSAGE\", \"icon_emoji\": \":robot_face:\"}" $SLACK_HOOK
}

function deploy_started () {
  START_TIME="$(date +%s)"
  post "$REPO_NAME's $FEATURE was merged into $BRANCH and :$DOCKER_IMAGE_TAG is being continuously deployed to $ECS_SERVICE in the $ECS_CLUSTER cluster"
}

function deploy_finished () {
  END_TIME="$(date +%s)"
  TOTAL_TIME=$((END_TIME-START_TIME))
  post "$REPO_NAME's :$DOCKER_IMAGE_TAG was successfully (and continuously) deployed to $ECS_SERVICE in the $ECS_CLUSTER cluster in $TOTAL_TIME second(s)\nLast Commit: $LAST_COMMIT\nHealth: $HEALTH_CHECK_URL\nServices Health: $SERVICES_HEALTH_CHECK_URL"
}

echo " - Downloading the latest ecsman"
curl -L https://github.com/womply/ecsman/blob/master/bin/ecsman.linux?raw=true > ecsman
chmod +x ecsman

if [ "$DOCKER_IMAGE_TAG" == "develop" ] || [ "$DOCKER_IMAGE_TAG" == "alpha" ]; then
  BRANCH=$DOCKER_IMAGE_TAG
  SLACK_CHANNEL=#alerts-ruby-services
else
  SLACK_CHANNEL=#releases
  BRANCH=master
fi

echo " - Deploying :$DOCKER_IMAGE_TAG to $ECS_SERVICE in the $ECS_CLUSTER cluster"
deploy_started
./ecsman -cred env update $ECS_CLUSTER $ECS_SERVICE :$DOCKER_IMAGE_TAG

sleep 40

deploy_finished

if [ "$DOCKER_IMAGE_TAG" != "develop" ] && [ "$DOCKER_IMAGE_TAG" != "alpha" ]; then
  ./notify_error_tracker.sh
fi
