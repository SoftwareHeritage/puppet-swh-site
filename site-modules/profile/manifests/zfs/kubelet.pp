# Handle /var/lib/kubelet partition as zfs mountpoint
# To reduce the disk usage and use local storage when the second hard
# drive is configured to a local storage in terraform
class profile::zfs::kubelet {
  # as it's for rancher, we consider the zpool['data'] is
  # already installed by profile::zfs::docker
  zfs { 'data/kubelet':
    ensure      => present,
    atime       => 'off',
    compression => 'zstd',
    mountpoint  => '/var/lib/kubelet',
    require     => Zpool['data'],
  }
}
