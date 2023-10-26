class role::swh_storage inherits role::swh_base_storage {
  include profile::swh::deploy::objstorage_ceph
  include profile::swh::deploy::indexer_storage
}
