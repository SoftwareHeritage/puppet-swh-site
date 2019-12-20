# Apt configuration for Cassandra
class profile::cassandra::apt_config {
  $release = lookup('cassandra::release')

  class {'::cassandra::apache_repo':
    release => $release,
  }

  include profile::swh::apt_config::oldstable
}
