# Install docker-compose
class profile::docker_compose {
  package {'docker-compose':
    ensure => present,
  }
}
