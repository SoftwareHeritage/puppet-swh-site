class role::swh_storage_cloud inherits role::swh_base_storage {
  include ::profile::swh::deploy::objstorage_cloud
}
