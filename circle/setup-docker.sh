#!/usr/bin/env bash

# Installs an upgraded version of docker and starts it, logs in to quay.io and restores any
# cached docker images specified in docker_deps.yml
#
# Non Circle Provided Input Variables:
#   DOCKER_EMAIL: quay.io email (can be anything)
#   DOCKER_USER: quay.io username
#   DOCKER_PASS: quay.io encrypted password

set -e

sudo curl -L -o /usr/bin/docker 'http://s3-external-1.amazonaws.com/circle-downloads/docker-1.9.1-circleci'
sudo chmod 0755 /usr/bin/docker
sudo service docker start

docker login -e $DOCKER_EMAIL -u $DOCKER_USER -p $DOCKER_PASS quay.io

while IFS=: read DOCKERNAME DOCKERPATH; do
  if [ -e ~/docker_cache/${DOCKERNAME}.tar ]; then
    docker load -i ~/docker_cache/${DOCKERNAME}.tar
    docker pull ${DOCKERPATH}
  fi
done < docker_deps.yml
