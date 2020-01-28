# Deployment of the cassandra storage's dependencies
class profile::swh::deploy::storage_cassandra {
  package {'python3-cassandra':
    ensure  => present,
    require => Apt::Source['softwareheritage'],
  }
}
