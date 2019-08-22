class role::swh_kafka_broker inherits role::swh_base {
  include profile::puppet::agent
  include profile::kafka::broker
}
