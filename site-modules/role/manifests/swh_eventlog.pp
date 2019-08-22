class role::swh_eventlog inherits role::swh_kafka_broker {
  include profile::swh::deploy::indexer_journal_client
}
