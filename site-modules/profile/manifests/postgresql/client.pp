class profile::postgresql::client {
  include profile::postgresql::apt_config

  package { 'postgresql-client':
    ensure => present,
  }
}
