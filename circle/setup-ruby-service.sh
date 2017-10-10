#!/usr/bin/env bash
#
# Set up Docker and related dependencies for Ruby service deployment.
#
# Womply DevOps (Zee Alexander)

set -e
set -x

# SCRIPT = name of script
declare -rx SCRIPT=${0##*/}

# Psuedo-path for build-scripts
declare -rx BUILDSCRIPTS="${HOME}/build-scripts/circle"

# Required Items

declare -rx stop_competitors="${BUILDSCRIPTS}/stop-competitors.sh"
declare -rx setup_docker="${BUILDSCRIPTS}/setup-docker.sh"
declare -rx setup_ruby="${BUILDSCRIPTS}/setup-ruby.sh"

stat $stop_competitors
stat $setup_docker
stat $setup_ruby


if test ! -x "$stop_competitors"; then
    stat $stop_competitors
    printf "$SCRIPT:$LINENO: the command %s is not available - aborting\n" "$stop_competitors" >&2
    exit 192
fi

if test ! -x "$setup_docker"; then
    stat $setup_docker
    printf "$SCRIPT:$LINENO: the comma2nd %s is not available - aborting\n" "$setup_docker" >&2
    exit 192
fi

if test ! -x "$setup_ruby"; then
    stat $setup_ruby
    printf "$SCRIPT:$LINENO: the command %s is not available - aborting\n" "$setup_docker" >&2
    exit 192
fi

$stop_competitors
$setup_docker
$setup_ruby
