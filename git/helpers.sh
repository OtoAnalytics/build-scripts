#
# Deletes a branch locally and remotely
#
function gitdelete() {
  BRANCH="$1"
  if [ -n $BRANCH ]; then
    LOCAL_BRANCH_EXISTS=`git show-ref refs/heads/$BRANCH`
    REMOTE_BRANCH_EXISTS=`git ls-remote origin $BRANCH`
    if [ -n "$LOCAL_BRANCH_EXISTS" ]; then
      git branch -D $BRANCH;
    else
      echo "could not find local branch: $BRANCH"
    fi
    if [ -n "$REMOTE_BRANCH_EXISTS" ]; then
      git push origin --delete $BRANCH
    else
      echo "could not find remote branch: $BRANCH"
    fi
  fi
}

#
# Merges a remote source branch into a remote destination branch (that defaults to `develop`)
# and deletes the source branch locally and remotely
#
function gitmerge() {
  SOURCE_BRANCH="$1"
  DESTINATION_BRANCH="${2:-develop}"
  echo "merging $SOURCE_BRANCH into $DESTINATION_BRANCH..."
  if [[ $SOURCE_BRANCH == "" ]]; then
    echo "Please provide the name of the branch to be used"
    exit
  fi
  git stash && \
  git fetch origin $SOURCE_BRANCH && \
  git checkout $DESTINATION_BRANCH && \
  git pull origin $DESTINATION_BRANCH && \
  git merge origin/$SOURCE_BRANCH

  RETURN_CODE="$?"
  if [[ $RETURN_CODE == "0" ]]; then
    git push origin $DESTINATION_BRANCH && \
    gitdelete $SOURCE_BRANCH
  else
    echo "Operation aborted with return code $RETURN_CODE"
  fi
}

#
# Creates a release branch from an up-to-date `develop` branch and pushed it to remote
# Note: uncommited changes are stashed for you to recover later
#
function gitrelease() {
  git stash && \
  git checkout develop && \
  git pull origin develop && \
  git checkout -b release_$(date +"%Y%m%d%H%M%S") && \
  git push origin HEAD
}
