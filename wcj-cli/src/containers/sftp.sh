#!/usr/bin/env bash

start_sftp() {
  SFTP_CONTAINER_NAME=$1
  SFTP_HOST=$CONTAINERS_HOST_NAME
  SFTP_PORT=${SFTP_PORT:-2222}
  SFTP_BASE_DOCKER_IMAGE="atmoz/sftp"
  SFTP_DOCKER_IMAGE="$PROJECT_NAME-sftp-custom"

  if [ -z "$SFTP_USERS" ]; then
    die "SFTP container requires SFTP_USERS to be specified in project.env"
  fi

  build_sftp_image
  run_sftp_image
}

build_sftp_image() {
  DOCKER_CONTEXT_DIR=$(mktemp -d)
  DOCKERFILE_PATH="$DOCKER_CONTEXT_DIR/Dockerfile"

  append_line_to_dockerfile "FROM atmoz/sftp"
  while IFS= read -r line; do
    while IFS=, read -r username key_path uid gid home_dir; do
      host_key_path="${PROJECT_DIR}/${key_path}"
      docker_context_key_path="${username}.pub"
      docker_context_key_full_path="$DOCKER_CONTEXT_DIR/$docker_context_key_path"

      cp $host_key_path $docker_context_key_full_path
      append_line_to_dockerfile "COPY $docker_context_key_path /home/${username}/.ssh/keys/id_rsa.pub"

      PASSWD_ARG="${PASSWD_ARG}
${username}::${uid}:${gid}:${home_dir}"
    done < <(echo $line)
  done < <(printf '%s\n' "$SFTP_USERS")

  append_line_to_dockerfile 'EXPOSE 22'
  append_line_to_dockerfile 'ENTRYPOINT ["/entrypoint"]'

  exec_or_die docker build --tag $SFTP_DOCKER_IMAGE $DOCKER_CONTEXT_DIR

  rm -rf $DOCKER_CONTEXT_DIR
}

run_sftp_image() {
  exec_or_die docker run --name $SFTP_CONTAINER_NAME \
    -p $SFTP_PORT:22 -d --rm $SFTP_DOCKER_IMAGE \
    "${PASSWD_ARG}"

  docker_build_arg "SFTP_HOST" "$SFTP_HOST"
  docker_build_arg "SFTP_PORT" "$SFTP_PORT"
}

append_line_to_dockerfile() {
  $(echo -e "$1" >> $DOCKERFILE_PATH)
}
