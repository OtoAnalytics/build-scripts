#!/usr/bin/env bash
#
# Set up general Ruby dependencies
#
# Womply DevOps (Zee Alexander)
declare -r ruby_version_real="${RUBY_VERSION:-2.1.5}"
declare -r gem="/home/ubuntu/.rvm/rubies/ruby-${ruby_version_real}/bin/gem"

gem install bundler
