#!/usr/bin/env bash

start_sftp() {
  SFTP_CONTAINER_NAME=$1
  SFTP_HOST=$CONTAINERS_HOST_NAME
  SFTP_PORT=${SFTP_PORT:-2222}
  SFTP_DOCKER_IMAGE="atmoz/sftp"

  if [ -z "$SFTP_USERS" ]; then
    die "SFTP container requires SFTP_USERS to be specified in project.env"
  fi

  while IFS= read -r line; do
    while IFS=, read -r username key_path uid gid home_dir; do
      MOUNT_ARGS="${MOUNT_ARGS} --mount type=bind,source=`pwd`/${key_path},target=/home/${username}/.ssh/keys/id_rsa.pub,readonly"
      PASSWD_ARG="${PASSWD_ARG}
${username}:${uid}:${gid}:${home_dir}"
    done < <(echo $line)
  done < <(printf '%s\n' "$SFTP_USERS")

  exec_or_die docker run --name $SFTP_CONTAINER_NAME \
    ${MOUNT_ARGS} \
    -p $SFTP_PORT:22 -d --rm $SFTP_DOCKER_IMAGE \
    "${PASSWD_ARG}"

  docker_build_arg "SFTP_HOST" "$SFTP_HOST"
  docker_build_arg "SFTP_PORT" "$SFTP_PORT"
}
