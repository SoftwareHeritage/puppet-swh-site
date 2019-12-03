# Deploy the Docker daemon
class profile::docker {
  class {'::docker':
    dns => lookup('dns::local_nameservers'),
  }

  group {'docker':
    require => Package['docker'],
  }

  file {'/etc/docker/daemon.json':
    ensure  => 'absent',
  }
}
