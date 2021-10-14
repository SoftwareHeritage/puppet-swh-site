class role::swh_storage_with_journal inherits role::swh_base_storage {
  include profile::postgresql::client
  include profile::swh::deploy::journal::backfill

  # journal 
  include profile::zookeeper
  include profile::kafka::broker

}
