# Install and configure zfs
# Depends on kmod module
#
# swh::apt_config::enable_non_free must be set to true
class profile::zfs {
  $apt_non_free_enabled = lookup('swh::apt_config::enable_non_free');
  $total_server_memory = $memory["system"]["total_bytes"];
  $max_arc_memory_percent = lookup('zfs::arc::max_size_memory_percent')

  $zfs_arc_max_size = lookup('zfs::arc::max_size', {
    default_value => $total_server_memory * $max_arc_memory_percent / 100,
    value_type => Integer
  });

  if ! $apt_non_free_enabled {
    fail('swh::apt_config::enable_non_free must be set to true')
  }

  ensure_packages ('zfs-dkms')

  kmod::option { 'zfs_arc_max':
    module => 'zfs',
    option => 'zfs_arc_max',
    value  => $zfs_arc_max_size,
  }
}
