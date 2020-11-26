class role::swh_elasticsearch_broker inherits role::swh_elasticsearch {
  include profile::kafka::broker
}
