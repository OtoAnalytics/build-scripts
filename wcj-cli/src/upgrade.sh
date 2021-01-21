#!/usr/bin/env bash

upgrade() {
  require_var "AWS_ACCESS_KEY_ID"
  require_var "AWS_SECRET_ACCESS_KEY"

  exec_or_die "bash -c 'aws s3 cp s3://womply-builds/wcj-cli/install.sh - | sudo -E bash'"
}
