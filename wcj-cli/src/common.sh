
parse_common_opts() {
  while getopts ":p:" opt; do
    case ${opt} in
      p )
        export PROJECT_DIR=$OPTARG
        ;;
      \? )
        echo "Invalid option: -$OPTARG" 1>&2
        usage
        exit 1
        ;;
      : )
        echo "Invalid option: -$OPTARG requires an argument" 1>&2
        usage
        exit 1
        ;;
    esac
  done
}

