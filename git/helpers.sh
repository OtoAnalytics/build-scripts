#
# Open file or directory in web browser; defaults to current directory and branch
# Syntax: git-web [$file_or_dir] [$branch]
#
function gitweb() {
  file=${1:-""}
  git_branch=${2:-$(git symbolic-ref --quiet --short HEAD)}
  git_project_root=$(git config remote.origin.url | sed -r "s~(\w+@|https://|ssh://(\w+@)?)([^:^/]*)(:[0-9]+|)[:/](.*)\.git~https://\3\4/\5~")
  git_directory=$(git rev-parse --show-prefix)
  open ${git_project_root}/tree/${git_branch}/${git_directory}${file}
}

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
  git stash push -m "Files saved before merging branch $SOURCE_BRANCH" && \
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
# Creates a release branch from an up-to-date `develop` branch,
# pushes to remote, and opens PR form in browser
# Note: uncommited changes are stashed for you to recover later
#
function gitrelease() {
  timestamp=$(date +"%Y%m%d%H%M%S")
  release_branch="release_${timestamp}"
  git stash push -m "Files saved before creating release branch ${release_branch}" \
    && git checkout develop \
    && git pull origin develop \
    && git checkout -b ${release_branch} \
    && git push origin HEAD
  git_project_root=$(git config remote.origin.url | sed -r "s~(\w+@|https://|ssh://(\w+@)?)([^:^/]*)(:[0-9]+|)[:/](.*)\.git~https://\3\4/\5~")
  # Ref: https://docs.github.com/en/github/managing-your-work-on-github/about-automation-for-issues-and-pull-requests-with-query-parameters
  pull_request_url="${git_project_root}/compare/master...${release_branch}?expand=1&title=Release%20${timestamp}&body="
  echo "Pull Request URL: ${pull_request_url}"
  open ${pull_request_url}
}

#
# Merges a remote release branch into remote master branch
# and deletes the release branch locally and remotely
#
gitmergemaster() {
    source_branch=${1:-$(git symbolic-ref --quiet --short HEAD)}
    echo "source_branch = ${source_branch}"
    if [[ -z $(echo ${source_branch} | grep release_) ]]; then
        echo "'${source_branch}' is an invalid release branch name"
    else
        echo "Merging branch '$source_branch' into master"
        gitmerge $source_branch master
    fi
}
