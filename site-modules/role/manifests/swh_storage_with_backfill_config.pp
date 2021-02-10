class role::swh_storage_with_backfill_config inherits role::swh_base_storage {
  include profile::postgresql::client
  include profile::swh::deploy::journal::backfill
}
