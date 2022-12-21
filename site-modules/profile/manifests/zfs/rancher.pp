# Handle /var/lib/rancher partition as zfs mountpoint
# On the vms, to reduce the disk usage and use local storage when the second hard
# drive is configured to a local storage in terraform
class profile::zfs::rancher {
  # as it's for rancher, we consider the zpool['data'] is
  # already installed by profile::zfs::docker
  zfs { 'data/rancher':
    ensure      => present,
    atime       => 'off',
    compression => 'zstd',
    mountpoint  => '/var/lib/rancher',
    require     => Zpool['data'],
  }
}
