#!/usr/bin/env bash

# Generates tags and release notes for builds of the master branch
#
# Non Circle Provided Input Variables:
#   CURRENT_VERSION: mvn version of the completed build
#   GITHUB_AUTH_TOKEN: auth token to hit the github API with

set +e

if [ "${CIRCLE_BRANCH}" = "master" ]; then
  git tag ${CURRENT_VERSION}
  git push origin --tags
  PREVIOUS_VERSION=$(git tag | sort -V |grep ${CURRENT_VERSION} -B1 |head -n 1)
  RELEASE_NOTES=$(git log --pretty=format:'* %s\r\n' ${PREVIOUS_VERSION}..${CURRENT_VERSION} | sed 's/"/\\"/g'|tr -d '\n')
  if [ "${GITHUB_AUTH_TOKEN}" != "" -a "${RELEASE_NOTES}" != "" ]; then
    TAG_HTTP_CODE=$(curl -o/dev/null -s -I -w "%{http_code}" -H "Authorization: token ${GITHUB_AUTH_TOKEN}" "https://api.github.com/repos/${CIRCLE_PROJECT_USERNAME}/${CIRCLE_PROJECT_REPONAME}/git/refs/tags/${CURRENT_VERSION}")
    TRIES=0
    while [ ${TAG_HTTP_CODE} -ne 200 -a $TRIES -lt 10 ]; do
      TAG_HTTP_CODE=$(curl -o/dev/null -s -I -w "%{http_code}" -H "Authorization: token ${GITHUB_AUTH_TOKEN}" "https://api.github.com/repos/${CIRCLE_PROJECT_USERNAME}/${CIRCLE_PROJECT_REPONAME}/git/refs/tags/${CURRENT_VERSION}")
      TRIES=$(($TRIES+1));
      if [ ${TAG_HTTP_CODE} -ne 200 ]; then
        echo $TAG_HTTP_CODE
        echo $TRIES
        sleep 1
      fi
    done
    sleep 5
    curl -H "Authorization: token ${GITHUB_AUTH_TOKEN}" -X POST "https://api.github.com/repos/${CIRCLE_PROJECT_USERNAME}/${CIRCLE_PROJECT_REPONAME}/releases" -H "Content-Type: application/json" -d "{\"tag_name\":\"${CURRENT_VERSION}\", \"body\": \"${RELEASE_NOTES}\"}"
  fi
fi
