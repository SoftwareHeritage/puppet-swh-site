class role::swh_storage_cloud inherits role::swh_base {
  include profile::swh::deploy::storage
  include ::profile::swh::deploy::objstorage_cloud
}
