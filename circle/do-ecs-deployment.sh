#!/usr/bin/env bash

# Deploys docker images as specified in docker_services.yml to ecs
#
# Non Circle Provided Input Variables:
#   REPO_ROOT: URL to the docker repository organization (eg quay.io/womply)
#   SPECIFIC_BRANCH: docker image tag, generally ${TIMESTAMP}-${CIRCLE_BRANCH}-${CIRCLE_SHA1}
#   ECS_PROD_CLUSTER: cluster to deploy the master branch to
#   ECS_PREPROD_CLUSTER: cluster to deploy the develop branch to
#   AWS_ACCESS_KEY_ID: access key for AWS account to connect to ECS with
#   AWS_SECRET_ACCESS_KEY: secret key for AWS account to connect to ECS with

set -e
set -x

curl -sL https://github.com/womply/ecsman/blob/master/bin/ecsman.linux?raw=true > ./ecsman
chmod +x ./ecsman
while IFS=: read REPO ECS_SERVICE; do
  # retag ${SPECIFIC_BRANCH}, then deploy based on that tag
  docker tag ${REPO_ROOT}/${REPO}:${CIRCLE_BRANCH} ${REPO_ROOT}/${REPO}:${SPECIFIC_BRANCH}
  docker push ${REPO_ROOT}/${REPO}:${SPECIFIC_BRANCH}
  if [ "${CIRCLE_BRANCH}" = "master" -o "${CIRCLE_BRANCH}" = "java-master" ]; then
    ECSMAN_ARGS="${ECS_PROD_CLUSTER} ${ECS_SERVICE}${PROD_ECS_SUFFIX} :${SPECIFIC_BRANCH}"
  else
    if [[ $ECS_PREPROD_CLUSTER =~ ^beta.* ]]; then
      ECS_SERVICE_PREFIX='beta-'
      ECSMAN_ARGS="${ECS_PREPROD_CLUSTER} ${ECS_SERVICE_PREFIX}${REPO}${PREPROD_ECS_SUFFIX} :${SPECIFIC_BRANCH}"
    else
      ECSMAN_ARGS="${ECS_PREPROD_CLUSTER} ${ECS_SERVICE}${PREPROD_ECS_SUFFIX} :${SPECIFIC_BRANCH}"
    fi
  fi
  ./ecsman -cred env update $ECSMAN_ARGS
done < docker_services.yml
