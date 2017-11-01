#!/usr/bin/env bash
#
# Build Ruby Service Containers
#
# Womply DevOps (Zee Alexander)

set -e
set -x

# SCRIPT = name of script
declare -rx SCRIPT=${0##*/}

# Required Items

declare -rx docker="/usr/bin/docker"

if test ! -x "$docker"; then
    stat $docker
    printf "$SCRIPT:$LINENO: the command %s is not available - aborting\n" "$docker" >&2
    exit 192
fi

docker build --no-cache -t quay.io/womply/$CIRCLE_PROJECT_REPONAME:$CIRCLE_SHA1 .
