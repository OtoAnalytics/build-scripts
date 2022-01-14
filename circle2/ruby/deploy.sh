#!/usr/bin/env bash

DOCKER_IMAGE_TAG=${1:-'latest'}
ECS_CLUSTER=${3:-'default'}
ECS_SERVICE=${4:-'default'}
ENVIRONMENT_INSTANCE=${2:-'default'}
FEATURE="${LAST_COMMIT_MESSAGE##*/}"
LAST_COMMIT=$(git rev-parse HEAD)
LAST_COMMIT_MESSAGE=$(git log -1 --pretty='%s')
TIMESTAMP=$(date +"%Y%m%d-%H%M%S")
export SPECIFIC_BRANCH=${TIMESTAMP}-${CIRCLE_BRANCH}-${CIRCLE_SHA1:0:7}
MANIFESTS_BRANCH="master"
MANIFESTS_DIR="manifests-repo"
MANIFESTS_GITHUB_REPO='OtoAnalytics/microservice-manifests'

if [[ "${CIRCLE_BRANCH}" == 'master' ]]; then
  EKS_ENVIRONMENT='prod'
else
  EKS_ENVIRONMENT='beta'
fi

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
# Deploy to ECS if the service exists in ECS
if [[ ! `aws ecs list-services --cluster ${ECS_CLUSTER} | grep $CIRCLE_PROJECT_REPONAME | wc -l` -eq 0 ]]; then
  ./ecsman -cred env update $ECS_CLUSTER $ECS_SERVICE :$DOCKER_IMAGE_TAG
fi

# Deploy to EKS if the service config exists in the microservice manifests
[[ -d ${MANIFESTS_DIR} ]] || git clone --single-branch --branch ${MANIFESTS_BRANCH} https://${WOMPLY_CIRCLECI_SHARED_USER_GITHUB_ACCESS_TOKEN}@github.com/${MANIFESTS_GITHUB_REPO}.git ${MANIFESTS_DIR}
if [[ -f "${MANIFESTS_DIR}/src/environments/${EKS_ENVIRONMENT}/image-tags/${CIRCLE_PROJECT_REPONAME}.yaml" ]]; then
  $(dirname $0)/../do-eks-deployment.sh ${SPECIFIC_BRANCH} ${EKS_ENVIRONMENT}
fi

sleep 40

deploy_finished

if [ "$DOCKER_IMAGE_TAG" != "develop" ] && [ "$DOCKER_IMAGE_TAG" != "alpha" ]; then
  ~/build-scripts/circle2/ruby/notify_error_tracker.sh
fi
