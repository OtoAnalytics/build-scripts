#!/usr/bin/env bash

TARBALL_URL="s3://womply-builds/wcj-cli/wcj-cli.tgz"
TARBALL_EXPLODE_DIR="/usr/local"

WCJ_DIR="${TARBALL_EXPLODE_DIR}/wcj-cli"
WCJ_EXEC="${WCJ_DIR}/bin/wcj"
IN_PATH_SYMLINK="${TARBALL_EXPLODE_DIR}/bin/wcj"

set -e

# Delete the old code
[ -L "$IN_PATH_SYMLINK" ] && rm "$IN_PATH_SYMLINK"
[ -d "$WCJ_DIR" ] && rm -rf "$WCJ_DIR"

# Install the new code
mkdir "$WCJ_DIR"
aws s3 cp "$TARBALL_URL" - | tar xvz -C "$TARBALL_EXPLODE_DIR"
ln -s "$WCJ_EXEC" "$IN_PATH_SYMLINK"
