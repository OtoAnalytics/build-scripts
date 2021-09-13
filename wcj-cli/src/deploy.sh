#!/usr/bin/env bash

. "$WCJ_DIR/src/build.sh"

deploy_eks() {
  # TODO Implement this
  die "Deploys to EKS are currently unsupported"
}

deploy_ecs() {
  push_docker_images
  run_ecsman
}

run_ecsman() {
  echo "Deploying via ECSMAN"

  if [ "${BRANCH}" = "master" -o "${BRANCH}" = "java-master" ]; then
    if [ "${ECS_PROD_CLUSTER}" = "prod-services" ]; then
      ECS_SERVICE_PREFIX='prod-'
      ECSMAN_ARGS="${ECS_PROD_CLUSTER} ${ECS_SERVICE_PREFIX}${PROJECT_NAME} :${FULL_TAG}"
    elif [ "${ECS_PROD_CLUSTER}" = "prod-cde" ] ; then
      ECS_SERVICE_PREFIX='prod-cde-'
      ECSMAN_ARGS="${ECS_PROD_CLUSTER} ${ECS_SERVICE_PREFIX}${PROJECT_NAME} :${FULL_TAG}"
    elif [ "${ECS_PROD_CLUSTER}" = "prod-cdeaccess" ] ; then
      ECS_SERVICE_PREFIX='prod-cdeaccess-'
      ECSMAN_ARGS="${ECS_PROD_CLUSTER} ${ECS_SERVICE_PREFIX}${PROJECT_NAME} :${FULL_TAG}"
    else
      ECSMAN_ARGS="${ECS_PROD_CLUSTER} ${ECS_SERVICE} :${FULL_TAG}"
    fi
  else
    if [[ $ECS_PREPROD_CLUSTER =~ ^beta.* ]]; then
      ECS_SERVICE_PREFIX='beta-'
      ECSMAN_ARGS="${ECS_PREPROD_CLUSTER} ${ECS_SERVICE_PREFIX}${PROJECT_NAME} :${FULL_TAG}"
    else
      ECSMAN_ARGS="${ECS_PREPROD_CLUSTER} ${ECS_SERVICE} :${FULL_TAG}"
    fi
  fi

  exec_or_die ecsman -cred env update $ECSMAN_ARGS
}

push_docker_images() {
  echo "Pushing Docker Images"

  exec_or_die docker tag $DOCKER_IMAGE $DOCKER_FULL_TAG_IMAGE
  exec_or_die docker push $DOCKER_IMAGE
  exec_or_die docker push $DOCKER_FULL_TAG_IMAGE
}

deploy() {
  require_wcj_project
  git_and_docker_vars

  if [ "$DEPLOY_TYPE" = "ecs" ]; then
    deploy_ecs
  elif [ "$DEPLOY_TYPE" = "eks" ]; then
    deploy_eks
  else
    die "Unknown deploy type for project: $DEPLOY_TYPE"
  fi
}
