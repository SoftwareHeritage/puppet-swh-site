# Handle mount points
class profile::mountpoints {
  $mountpoints = hiera_hash('mountpoints')

  each($mountpoints) |$mountpoint, $config| {
    if (has_key($config, 'options') and $config['options'] =~ Array) {
      $mount_config = $config + {
        options => join($config['options'], ','),
      }
    } else {
      $mount_config = $config
    }

    file {$mountpoint:
      ensure => directory,
    }

    mount {$mountpoint:
      ensure   => present,
      dump     => 0,
      pass     => 0,
      options  => 'defaults',
      *        => $mount_config,
      requires => File[$mountpoint],
    }
  }
}
