# Handle /var/lib/docker partition as zfs mountpoint
# To reduce the disk usage
class profile::zfs::docker {
  # zpool create -f data /dev/vdb
  zpool {'data':
    ensure => 'present',
    disk   => 'vdb',
  }

  # zfs create -o mountpoint=/var/lib/docker \
  #   -o atime=off \
  #   -o relatime=on \  # not supported by the following
  #   -o compression=zstd \
  #   data/docker

  zfs { 'data/docker':
    ensure      => present,
    atime       => 'off',
    compression => 'zstd',
    mountpoint  => '/var/lib/docker',
    require     => Zpool['data'],
    notify      => Service['docker'],
  }
  -> Package['docker']
}
