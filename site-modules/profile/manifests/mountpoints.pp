# Handle mount points
class profile::mountpoints {
  $mountpoints = lookup('mountpoints', Hash, 'deep')

  each($mountpoints) |$mountpoint, $config| {
    if (has_key($config, 'options') and $config['options'] =~ Array) {
      $mount_config = $config + {
        options => join($config['options'], ','),
      }
    } else {
      $mount_config = $config
    }

    if pick($config['ensure'], 'present') != 'absent' {
      exec {"create ${mountpoint}":
        creates => $mountpoint,
        command => "mkdir -p ${mountpoint}",
        path    => ['/bin', '/usr/bin', '/sbin', '/usr/sbin'],
      }
      -> file {$mountpoint:}
      -> mount {
        default:
          ensure  => present,
          dump    => 0,
          pass    => 0,
          options => 'defaults';
        $mountpoint:
          *       => $mount_config,
      }
    }
  }
}
