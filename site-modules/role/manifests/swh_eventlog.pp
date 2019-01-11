class role::swh_eventlog inherits role::swh_base {
  include profile::puppet::agent

  include profile::kafka::broker
  include profile::swh::deploy::storage_listener
  include profile::swh::deploy::indexer_journal_client
}
