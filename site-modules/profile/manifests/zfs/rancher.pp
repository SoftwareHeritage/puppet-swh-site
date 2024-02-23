# Handle /var/lib/rancher partition as zfs mountpoint
# On the vms, to reduce the disk usage and use local storage when the second hard
# drive is configured to a local storage in terraform
class profile::zfs::rancher {
  include ::profile::zfs::common
  # as it's for rancher, we consider the zpool['data'] is
  # already installed by profile::zfs::docker
  zfs { 'data/rancher':
    ensure      => present,
    atime       => 'off',
    compression => 'zstd',
    mountpoint  => '/var/lib/rancher',
    require     => Zpool['data'],
  }
  # This pool is used to create volumes that must be kept
  # if the server restarts. It's used by the local-path-provisioner tool
  zfs { 'data/volumes':
    ensure      => present,
    atime       => 'off',
    compression => 'zstd',
    mountpoint  => '/srv/kubernetes/volumes',
    require     => Zpool['data'],
  }
}
