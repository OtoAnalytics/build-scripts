#!/usr/bin/env bash

# Posts a notification to the default slack channel associated with the given webhook URL
#
# Non Circle Provided Input Variables:
#   SLACK_NOTIFICATION_WEBHOOK: URL to a slack notification webhook
#   CURRENT_VERSION: mvn version of the completed build
#   SPECIFIC_BRANCH: docker image tag, generally ${TIMESTAMP}-${CIRCLE_BRANCH}-${CIRCLE_SHA1}

set +e

if [ "${SLACK_NOTIFICATION_WEBHOOK}" != "" ]; then
  if [ "${SLACK_CHANNEL}" != "" ]; then
    curl -X POST -d "payload={\"username\":\"Github\", \"channel\":\"${SLACK_CHANNEL}\", \"icon_emoji\":\":octocat:\", \"attachments\":[{ \"mrkdwn_in\":[\"text\"], \"color\":\"#439FE0\", \"fallback\":\"Merge Notification\", \"pretext\":\"Merge Notification\", \"text\":\"*Project* \`${CIRCLE_PROJECT_REPONAME}\`\n*Branch* \`${CIRCLE_BRANCH}\`\n*Version* \`${CURRENT_VERSION}\`\n*Docker Image* \`${SPECIFIC_BRANCH}\`\nClick <$CIRCLE_COMPARE_URL|here> to see what changed\"}]}" ${SLACK_NOTIFICATION_WEBHOOK}
  else
    curl -X POST -d "payload={\"username\":\"Github\", \"icon_emoji\":\":octocat:\", \"attachments\":[{ \"mrkdwn_in\":[\"text\"], \"color\":\"#439FE0\", \"fallback\":\"Merge Notification\", \"pretext\":\"Merge Notification\", \"text\":\"*Project* \`${CIRCLE_PROJECT_REPONAME}\`\n*Branch* \`${CIRCLE_BRANCH}\`\n*Version* \`${CURRENT_VERSION}\`\n*Docker Image* \`${SPECIFIC_BRANCH}\`\nClick <$CIRCLE_COMPARE_URL|here> to see what changed\"}]}" ${SLACK_NOTIFICATION_WEBHOOK}
  fi
fi
