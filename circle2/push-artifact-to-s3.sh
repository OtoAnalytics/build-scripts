#!/usr/bin/env bash
# Pushes a build artifact for a specific repository to a specified S3 location

info() {
  echo "usage: $0 [ -l s3_location ] [ -r repository ] [ -a artifact_path ]"
  echo
  echo "  -l s3_location        Required: The Amazon S3 location to which to push the artifact"
  echo "  -r repository         Required: The repository of the project from which the artifact is built"
  echo "  -a artifact_path      Required: The path to the artifact object (jar, tar, etc.) to store in Amazon S3"
  echo
}

parse_options() {
	while getopts "hl:r:a:" opt; do
		case "$opt" in
			h)
				info >&2
				exit 0
				;;
			l)
				S3_LOCATION=$OPTARG
				;;
			r)
				REPOSITORY=$OPTARG
				;;
			a)
				ARTIFACT_PATH=$OPTARG
				ARTIFACT_FILE_SUFFIX="${ARTIFACT_PATH##*.}"
				;;
			'?')
				info >&2
				exit 1
				;;
		esac
	done
}

copy_to_s3() {
	aws s3 cp \
		${ARTIFACT_PATH} \
		s3://${S3_LOCATION}/${REPOSITORY}-${CIRCLE_BRANCH}.${ARTIFACT_FILE_SUFFIX}
}

run_script() {
	echo "Copying $ARTIFACT_PATH for $REPOSITORY to s3://$S3_LOCATION."
	copy_to_s3
}

parse_options "$@"
run_script

