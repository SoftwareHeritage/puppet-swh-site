class role::swh_storage_baremetal inherits role::swh_storage {
  include profile::dar::server
  include profile::megacli
  include profile::multipath
  include profile::mountpoints

  include ::profile::swh::deploy::objstorage_cloud
}
