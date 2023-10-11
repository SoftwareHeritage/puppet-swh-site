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
    storage_driver => $storage_driver,
  }

  group {'docker':
    require => Package['docker'],
  }

  file {'/etc/docker/daemon.json':
    ensure => 'absent',
  }
}
