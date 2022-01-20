class role::swh_journal_orchestrator inherits role::swh_base {
  include profile::kafka
  include profile::kafka::prometheus_consumer_group_exporter
  include profile::kafka::management_scripts
}
