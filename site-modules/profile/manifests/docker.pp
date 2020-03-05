# Deploy the Docker daemon
class profile::docker {
  class {'::docker':
    dns        => lookup('dns::local_nameservers'),
    log_driver => 'journald',
  }

  group {'docker':
    require => Package['docker'],
  }

  file {'/etc/docker/daemon.json':
    ensure  => 'absent',
  }
}
