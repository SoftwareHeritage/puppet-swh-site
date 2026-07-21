# Deploy the Docker daemon
class profile::docker {
  if $facts['mountpoints']['/var/lib/docker'] {
    if $facts['mountpoints']['/var/lib/docker']['filesystem'] == 'zfs' {
      $storage_driver = 'zfs'
    }
  }
  else {
    $storage_driver = undef
  }

  class {'::docker':
    dns            => lookup('dns::local_nameservers'),
    log_driver     => 'journald',
    socket_bind    => 'fd://',
    socket_group   => false,
    storage_driver => $storage_driver,
  }

  group {'docker':
    require => Package['docker'],
  }

  $docker_daemon_config = lookup('docker::daemon::config', { 'default_value' => undef })
  if $docker_daemon_config {
    file {'/etc/docker/daemon.json':
      ensure  => 'present',
      content => template('profile/docker/daemon.json.erb'),
      notify  => Service['docker'],
    }
  } else {
    file {'/etc/docker/daemon.json':
      ensure => 'absent',
    }
  }
}
