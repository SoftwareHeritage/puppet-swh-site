class role::swh_storage_baremetal inherits role::swh_storage {
  include profile::dar::server
  include profile::megacli
}
