class role::swh_kafka_broker inherits role::swh_base {
  include profile::zfs::kafka
  include profile::zookeeper
  include profile::kafka::broker

  if lookup("swh::kafkabackup::enable") == true {
    include profile::kafka::kafkabackup_broker
  }
}
