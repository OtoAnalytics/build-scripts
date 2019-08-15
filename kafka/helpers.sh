KAFDROP_SERVICE_PORT="9000"
KAFKA_DOCKER_CONTAINER="kafka"
KAFKA_DOCKER_IMAGE="spotify/kafka"
KAFKA_HOME="/opt/kafka_2.11-0.10.1.0"
KAFKA_ZK_PORT="2181"
KAFKA_ENV="prod"
KAFKA_HOST_PREFIX="sds-support1-"
KAFKA_PORT="9092"
KAFKA_UNTOUCHABLE_TOPICS="__consumer_offsets|failover"

#
# Lists all the Kafka topics
#
function kaf-list() {
  kaf-reset-vars
  kaf-command "kafka-topics.sh --list --zookeeper $KAFKA_ZK_HOST"
}

#
# Creates a new Kafka topic
#
function kaf-create() {
  local TOPIC="$1"
  PARTITION_COUNT="${2:-1}"
  REPLICATION_COUNT="${3:-1}"
  kaf-reset-vars
  kaf-command "kafka-topics.sh --create --zookeeper $KAFKA_ZK_HOST --replication-factor $REPLICATION_COUNT --partitions $PARTITION_COUNT --topic $TOPIC"
}

#
# Deletes a Kafka topic (only if delete.topic.enable is set to true)
#
function kaf-delete() {
  local TOPIC="$1"
  kaf-reset-vars
  kaf-command "kafka-topics.sh --zookeeper $KAFKA_ZK_HOST --delete --topic $TOPIC"
}

#
# Describes a Kafka topic
#
function kaf-describe() {
  local TOPIC="$1"
  kaf-reset-vars
  kaf-command "kafka-topics.sh --zookeeper $KAFKA_ZK_HOST --describe --topic $TOPIC"
}

#
# Reads the next n messages (without dequeuing them) from the specified Kafka topic; if n is not specified, one message is read
#
function kaf-peek() {
  local TOPIC="$1"
  local MESSAGE_COUNT="${2:-1}"
  kaf-reset-vars
  kaf-command "kafka-console-consumer.sh --zookeeper $KAFKA_ZK_HOST --topic $TOPIC --from-beginning --max-messages $MESSAGE_COUNT"
}

#
# Returns the number of messages in every partition for a given Kafka topic, as well as the overall total
#
function kaf-get-message-count() {
  local TOPIC="$1"
  kaf-reset-vars
  local OUTPUT=`kaf-command "kafka-run-class.sh kafka.tools.GetOffsetShell --broker-list $KAFKA_HOST --topic $TOPIC --time -1 --offsets 1"`
  echo $OUTPUT
  echo
  echo "-- Total message count:"
  echo $OUTPUT | awk -F ':' '{sum += $3} END {print sum}'
}

#
# Returns the first offset of every partition for a given Kafka topic
#
function kaf-get-first-offset() {
  local TOPIC="$1"
  kaf-reset-vars
  kaf-command "kafka-run-class.sh kafka.tools.GetOffsetShell --broker-list $KAFKA_HOST --topic $TOPIC --time -2"
}

#
# Returns the last offset of every partition for a given Kafka topic
#
function kaf-get-last-offset() {
  local TOPIC="$1"
  kaf-reset-vars
  kaf-command "kafka-run-class.sh kafka.tools.GetOffsetShell --broker-list $KAFKA_HOST --topic $TOPIC --time -1"
}

#
# Starts the drainage of the specified Kafka topic by adding a message retention policy of 1 second
#
function kaf-start-draining() {
  local TOPIC="$1"
  kaf-config $TOPIC "--add-config retention.ms=1000"
}

#
# Starts the drainage of all the Kafka topics except the untouchable ones
#
function kaf-start-draining-all() {
  kaf-reset-vars
  local KAFKA_TOPICS=(`kaf-list | grep -Ev "$KAFKA_UNTOUCHABLE_TOPICS"`)
  for topic in "${KAFKA_TOPICS[@]}"; do
    echo " - Processing $topic"
    kaf-start-draining $topic
  done
  echo "All touchable topics got reconfigured for drainage on $KAFKA_HOST"
}

#
# Removes the message retention entry from the config of the specified Kafka topic
#
function kaf-reset() {
  local TOPIC="$1"
  kaf-config $TOPIC "--delete-config 'retention.ms'"
}

#
# Removes the message retention entry from the config of all the Kafka topics except the untouchable ones
#
function kaf-reset-all() {
  kaf-reset-vars
  local KAFKA_TOPICS=(`kaf-list | grep -Ev "$KAFKA_UNTOUCHABLE_TOPICS"`)
  for topic in "${KAFKA_TOPICS[@]}"; do
    echo " - Processing $topic"
    kaf-reset $topic
  done
  echo "All touchable topics got reset on $KAFKA_HOST"
}

#
# Alters the config of the specified Kafka topic
#
function kaf-config() {
  local TOPIC="$1"
  local CONFIG="$2"
  kaf-reset-vars
  kaf-command "kafka-configs.sh --zookeeper $KAFKA_ZK_HOST --alter --entity-type topics --entity-name $TOPIC $CONFIG"
}

#
# Runs a message producer console that accepts input messages and sends them to the given topic
#
function kaf-run-producer() {
  local TOPIC="$1"
  kaf-reset-vars
  kaf-command "kafka-console-producer.sh --broker-list $KAFKA_HOST --topic $TOPIC"
}

#
# Runs a message consumer console that consumes queued messages from the given topic and displays them
#
function kaf-run-consumer() {
  local TOPIC="$1"
  kaf-reset-vars
  kaf-command "kafka-console-consumer.sh --bootstrap-server $KAFKA_HOST --topic $TOPIC --from-beginning"
}

#
# Executes a Kafka script within the Kafka Docker container
#
function kaf-command() {
  local KAFKA_COMMAND="$1"
  kaf-docker-exec "$KAFKA_HOME/bin/$KAFKA_COMMAND"
}

#
# Executes a bash command within the Kafka Docker container
#
function kaf-docker-exec() {
  local COMMAND="$1"
  docker exec -it $KAFKA_DOCKER_CONTAINER bash -c $COMMAND
}

#
# Starts the Kafka Docker container so that Kafka scripts can run against it
#
function kaf-docker-run() {
  docker run -d --rm -p 2181:2181 -p 9092:9092 -e ADVERTISED_PORT=9092 --name kafka $KAFKA_DOCKER_IMAGE
}

#
# Launches the Kafdrop dashboard
#
function kafdrop() {
  open "http://localhost:$KAFDROP_SERVICE_PORT"
  kaf-reset-vars
  docker run --rm -p $KAFDROP_SERVICE_PORT:9000 \
    -e ZOOKEEPER_CONNECT="$KAFKA_ZK_HOST" \
    -e KAFKA_BROKERCONNECT="$KAFKA_HOST" \
    -e JVM_OPTS="-Xms32M -Xmx64M" \
    -e SERVER_SERVLET_CONTEXTPATH="/" \
    --name kafdrop \
    obsidiandynamics/kafdrop:latest
}

#
# Resets Kafka environment variables
#
function kaf-reset-vars() {
  KAFKA_HOST="$KAFKA_HOST_PREFIX$KAFKA_ENV.internal.womply.com:$KAFKA_PORT"
  KAFKA_ZK_HOST="$KAFKA_HOST_PREFIX$KAFKA_ENV.internal.womply.com:$KAFKA_ZK_PORT"
}

#
# Opens all SDS dashboards and relevant endpoints
#
function kaf-open-sds-dashboards() {
  # DataDog dashboad for Kafka metrics
  open "https://app.datadoghq.com/screen/integration/50/Kafka%20-%20Overview?tpl_var_scope=host%3Asds-support1-prod.internal.womply.com"
  # DataDOg dashboad for Kafka nodes
  open "https://app.datadoghq.com/infrastructure?filter=sds-support%20environment%3Aprod"
  # DataDog dashboard for SDS
  open "https://app.datadoghq.com/dashboard/ufw-4zk-bb6/sds-display-dash?from_ts=1561486973138&live=true&to_ts=1564078973138&tv_mode=true"
  # scraper-service metrics, including queue sizes
  open "http://scraper-service.production:81/metrics?pretty=true"
  # scraper-service thread thread dump (to identify BLOCKED threads)
  open "http://scraper-service.production:81/threads"
  # proxy-service's available proxies
  open "http://proxy-service.prod/proxy/summary"
  # proxy-service memory and CPU utilization 
  open "https://us-west-2.signin.aws.amazon.com/oauth?response_type=code&client_id=arn%3Aaws%3Aiam%3A%3A015428540659%3Auser%2Fecs&redirect_uri=https%3A%2F%2Fus-west-2.console.aws.amazon.com%2Fecs%2Fhome%3Fregion%3Dus-west-2%26state%3DhashArgs%2523%252Fclusters%252Fprod-services%252Fservices%252Fprod-proxy-service%252Fmetrics%26isauthcode%3Dtrue&forceMobileLayout=0&forceMobileApp=0"
  # Live-site tests on Jenkins
  open "https://engci.internal.womply.com/view/SDS%20Dashboard/"
}

kaf-reset-vars
echo " - Kafka variables and helpers are now loaded!"
