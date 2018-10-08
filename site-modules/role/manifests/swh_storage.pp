class role::swh_storage inherits role::swh_server {
  include profile::puppet::agent
  include profile::swh::deploy::storage
  include profile::swh::deploy::indexer_storage
  include profile::swh::deploy::objstorage
  include profile::swh::deploy::worker
  include profile::swh::deploy::objstorage_cloud
  include profile::swh::deploy::objstorage_ceph
}
