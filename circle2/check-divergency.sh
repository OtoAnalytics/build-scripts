#!/usr/bin/env bash

# Ensures that the master has not diverged from develop


git checkout develop > /dev/null  2>&1
git checkout master > /dev/null 2>&1

git branch --contains master --format '%(refname:short)' | grep -q '^develop$'
contains_return=$?
if [ $contains_return -ne 0 ]; then
  echo "This git repo's master branch has diverged from develop!!!"
  exit 1
fi

git checkout "$CIRCLE_BRANCH"  > /dev/null  2>&1
