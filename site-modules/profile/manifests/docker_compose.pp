# Install docker compose v2
class profile::docker_compose {
  include profile::docker

  package {'docker-compose-plugin':
    ensure => installed,
  }

  package {'docker-compose':
    ensure => absent,
  }

  class {'docker::compose':
    ensure      => 'absent',
  }
}
