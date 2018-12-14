# Handle a /etc/puppet-cron.d directory with properly managed cron.d snippets

class profile::cron {
  $directory = '/etc/puppet-cron.d'

  file {$directory:
    ensure  => directory,
    mode    => '0755',
    owner   => 'root',
    group   => 'root',
    recurse => true,
    purge   => true,
    notify  => Exec['clean-cron.d-symlinks'],
  }

  exec {'clean-cron.d-symlinks':
    path        => ['/bin', '/usr/bin'],
    command     => 'find /etc/cron.d -type l ! -exec test -e {} \; -delete',
    refreshonly => true,
    require     => File[$directory],
  }
}
