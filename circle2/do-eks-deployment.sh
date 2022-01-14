#!/usr/bin/env bash

set -e
set -x

DOCKER_IMAGE_TAG="${1}"
ENVIRONMENT="${2}"
MANIFEST_BRANCH="${3:-master}"
MANIFEST_DIR="manifests-repo"
KUBERNETES_MANIFESTS_GITHUB_REPO="OtoAnalytics/microservice-manifests"
REPO=${CIRCLE_PROJECT_REPONAME}

if [ -z "$DOCKER_IMAGE_TAG" ] || [ -z "$ENVIRONMENT" ]; then
  echo "usage: $0 <DOCKER_IMAGE_TAG> <ENVIRONMENT> [MANIFEST_BRANCH]"
  exit 1
elif [ "$DOCKER_IMAGE_TAG" = "latest" ]; then
  echo "The tag 'latest' will significantly complicate rollbacks should the need arise. Please choose a different one."
  exit 1
fi

echo "=== pull docker image ==="
docker pull ${REPO_ROOT}/${REPO}:${CIRCLE_BRANCH}

DOCKER_IMAGE_COMBINED="${REPO_ROOT}/${REPO}:${DOCKER_IMAGE_TAG}"

echo "=== tag and push docker image ==="
docker tag ${REPO_ROOT}/${REPO}:${CIRCLE_BRANCH} ${DOCKER_IMAGE_COMBINED}
docker push ${DOCKER_IMAGE_COMBINED}

echo "=== Cloning Manifests Repo ==="
[[ -d ${MANIFEST_DIR} ]] || git clone --single-branch --branch ${MANIFEST_BRANCH} https://${WOMPLY_CIRCLECI_SHARED_USER_GITHUB_ACCESS_TOKEN}@github.com/${KUBERNETES_MANIFESTS_GITHUB_REPO}.git ${MANIFEST_DIR}
cd ${MANIFEST_DIR}

echo "=== Updating Image Tags ==="
if [ ! -z "${KUBERNETES_APPLICATIONS}" ]; then
  IFS=',' app_array=($KUBERNETES_APPLICATIONS)
  for application in "${app_array[@]}"; do
    [[ ${application} == *-service ]] || application="${application}-service"
    sed "s~^  tag: .*~  tag: ${DOCKER_IMAGE_TAG}~g" -i "src/environments/${ENVIRONMENT}/image-tags/${application}.yaml"
    git add "src/environments/${ENVIRONMENT}/image-tags/${application}.yaml"
  done
else
  application=${REPO}
  [[ ${application} == *-service ]] || application="${application}-service"
  sed "s~^  tag: .*~  tag: ${DOCKER_IMAGE_TAG}~g" -i "src/environments/${ENVIRONMENT}/image-tags/${application}.yaml"
  git add "src/environments/${ENVIRONMENT}/image-tags/${application}.yaml"
fi

echo "=== Commit & Push Changes to Manifests Repo ==="
git config user.name "womply-circleci-shared-user"
git config user.email "${CIRCLE_PROJECT_REPONAME}"
git commit -m "Auto-release ${CIRCLE_PROJECT_REPONAME}, build #${CIRCLE_BUILD_NUM}, environment ${ENVIRONMENT}"
git push --force origin HEAD
