#!/usr/bin/env bash

# Does a deploy to either ECS or EKS, sets up tags & release notes in github, and notifies slack
#
# Non Circle Provided Input Variables:
#   REPO_ROOT: URL to the docker repository organization (eg quay.io/womply)
#   ECS_PROD_CLUSTER: cluster to deploy the master branch to
#   ECS_PREPROD_CLUSTER: cluster to deploy the develop branch to
#   GITHUB_AUTH_TOKEN: auth token to hit the github API with
#   SLACK_NOTIFICATION_WEBHOOK: URL to a slack notification webhook

set -e

# Populate the necessary variables
export AWS_DEFAULT_REGION='us-west-2'
export CURRENT_VERSION=$(mvn -q -Dexec.executable="echo" -Dexec.args='${project.version}' --non-recursive exec:exec)
TIMESTAMP=$(date +"%Y%m%d-%H%M%S")
export SPECIFIC_BRANCH=${TIMESTAMP}-${CIRCLE_BRANCH}-${CIRCLE_SHA1:0:7}
MANIFESTS_GITHUB_REPO='OtoAnalytics/microservice-manifests'
MANIFESTS_BRANCH="master"
MANIFESTS_DIR="manifests-repo"
if [[ "${CIRCLE_BRANCH}" == 'master' ]]; then
  ECS_CLUSTER=$ECS_PROD_CLUSTER
  EKS_ENVIRONMENT='prod'
else
  ECS_CLUSTER=$ECS_PREPROD_CLUSTER
  EKS_ENVIRONMENT='beta'
fi

# Deploy to ECS if the service exists in ECS
if [[ ! `aws ecs list-services --cluster ${ECS_CLUSTER} | grep $CIRCLE_PROJECT_REPONAME | wc -l` -eq 0 ]]; then
  do-ecs-deployment.sh
fi

# Deploy to EKS if the service config exists in the microservice manifests
[[ -d ${MANIFESTS_DIR} ]] || git clone --single-branch --branch ${MANIFESTS_BRANCH} https://${WOMPLY_CIRCLECI_SHARED_USER_GITHUB_ACCESS_TOKEN}@github.com/${MANIFESTS_GITHUB_REPO}.git ${MANIFESTS_DIR}
if [[ -f "${MANIFESTS_DIR}/src/environments/${EKS_ENVIRONMENT}/image-tags/${CIRCLE_PROJECT_REPONAME}.yaml" ]]; then
  do-eks-deployment.sh ${SPECIFIC_BRANCH} ${EKS_ENVIRONMENT}
fi

# Execute post-deployment tasks
do-release-notes.sh
do-slack-notification.sh
