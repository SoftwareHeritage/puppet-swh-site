class role::swh_kafka_broker inherits role::swh_base {
  include profile::zookeeper
  include profile::kafka::broker
}
