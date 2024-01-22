class role::swh_storage_baremetal inherits role::swh_storage {
  include profile::megacli
  include profile::multipath
  include profile::mountpoints

  include ::profile::swh::deploy::objstorage_cloud

  # (Temporary) Inline the rancher node role's profiles (then make this class inherit
  # role::rancher_node once the swh rpc services are done being migrated)
  include profile::zfs::kubelet
  include profile::zfs::rancher
  include profile::kubernetes
}
