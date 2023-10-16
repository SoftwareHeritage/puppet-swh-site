class profile::zfs::common {
  $zpool_configuration = lookup('zfs::common::zpool_configuration')

  # zpool create -f data /dev/vdb
  zpool { 'data':
    ensure => 'present',
    *      => $zpool_configuration,
  }
}
