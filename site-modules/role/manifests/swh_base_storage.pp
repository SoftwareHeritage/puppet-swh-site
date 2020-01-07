class role::swh_base_storage inherits role::swh_server {
  include profile::swh::deploy::storage
  include profile::swh::deploy::indexer_storage
  include profile::swh::deploy::objstorage
}
