class role::swh_journal_orchestrator inherits role::swh_base {
  include profile::kafka
  include profile::kafka::prometheus_consumer_group_exporter
  include profile::swh::deploy::indexer_journal_client
}
