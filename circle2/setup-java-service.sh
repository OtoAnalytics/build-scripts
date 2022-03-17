#!/usr/bin/env bash

# Sets up docker, JCE unlimited, and maven
#
# Non Circle Provided Input Variables:
#   DOCKER_EMAIL: quay.io email (can be anything)
#   DOCKER_USER: quay.io username
#   DOCKER_PASS: quay.io encrypted password
#   MVN_SETTINGS_XML: contents of ~/.m2/settings.xml

set -e

check-divergency.sh
setup-docker.sh
setup-maven.sh "$@"
