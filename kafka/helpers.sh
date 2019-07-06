KAFKA_DOCKER_CONTAINER="kafka"
KAFKA_HOME="/opt/kafka_2.11-0.10.1.0"
KAFKA_HOST="sds-support1-prod:2181"
KAFKA_TOPICS=(
  prod-facebook-realtime
  prod-facebook-high
  prod-facebook-low
  prod-foursquare-realtime
  prod-foursquare-high
  prod-foursquare-low
  prod-google_plus-realtime
  prod-google_plus-high
  prod-google_plus-low
  prod-open_table-realtime
  prod-open_table-high
  prod-open_table-low
  prod-trip_advisor-realtime
  prod-trip_advisor-high
  prod-trip_advisor-low
  prod-yellow_pages-realtime
  prod-yellow_pages-high
  prod-yellow_pages-low
  prod-yelp-realtime
  prod-yelp-high
  prod-yelp-low
)

#
# Start the drainage of all the Kafka topics stored in $KAFKA_TOPICS
#
function kafkaStartDrainingAll() {
  for topic in "${KAFKA_TOPICS[@]}"; do
    echo " - Processing $topic"
    kafkaStartDraining $topic
  done
}

#
# Start the drainage of the specified Kafka topic by adding a message retention policy of 1 second
#
function kafkaStartDraining() {
  TOPIC="$1"
  kafkaConfig $TOPIC "--add-config retention.ms=1000"
}

#
# Removes the message retention entry from the config of all the Kafka topics stored in $KAFKA_TOPICS
#
function kafkaResetAll() {
  for topic in "${KAFKA_TOPICS[@]}"; do
    echo " - Processing $topic"
    kafkaReset $topic
  done
}

#
# Removes the message retention entry from the config of the specified Kafka topic
#
function kafkaReset() {
  TOPIC="$1"
  kafkaConfig $TOPIC "--delete-config 'retention.ms'"
}

#
# Alters the config of the specified Kafka topic
#
function kafkaConfig() {
  TOPIC="$1"
  CONFIG="$2"
  kafkaCommand "kafka-configs.sh --zookeeper $KAFKA_HOST --alter --entity-type topics --entity-name $TOPIC $CONFIG"
}

#
# Reads the next n messages (without dequeuing them) from the specified Kafka topic; if n is not specified, one message is read
#
function kafkaPeek() {
  TOPIC="$1"
  MESSAGE_COUNT="${2:-1}"
  kafkaCommand "kafka-console-consumer.sh --zookeeper $KAFKA_HOST --topic $TOPIC --from-beginning --max-messages $MESSAGE_COUNT"
}

#
# Executes a Kafka script within the Kafka Docker container
#
function kafkaCommand() {
  KAFKA_COMMAND="$1"
  kafkaDocker "$KAFKA_HOME/bin/$KAFKA_COMMAND"
}

#
# Executes a bash command within the Kafka Docker container
#
function kafkaDocker() {
  COMMAND="$1"
  docker exec -it $KAFKA_DOCKER_CONTAINER bash -c $COMMAND
}

#
# Starts the Kafka Docker container so that Kafka scripts can run against it
#
function kafkaDockerRun() {
  docker run -d --rm -p 2181:2181 -p 9092:9092 -e ADVERTISED_PORT=9092 --name kafka spotify/kafka
}

echo " - Kafka helpers are now loaded!"
