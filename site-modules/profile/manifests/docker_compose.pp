# Install docker-compose
class profile::docker_compose {
  package {'docker-compose':
    ensure => absent,
  }

  class {'docker::compose':
    ensure      => 'present',
    version     => lookup('docker::compose::version'),
    curl_ensure => false,
  }
}
