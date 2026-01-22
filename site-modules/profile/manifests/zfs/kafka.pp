# Handle /srv/kafka partition as zfs mountpoint
class profile::zfs::kafka {
  include ::profile::zfs::common

  zfs { 'data/kafka':
    ensure      => present,
    atime       => 'off',
    compression => 'lz4',
    mountpoint  => '/srv/kafka',
    require     => Zpool['data'],
  }
  -> Class[::profile::kafka::broker]
}
