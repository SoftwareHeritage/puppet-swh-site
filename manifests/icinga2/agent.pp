# Icinga2 agent configuration
class profile::icinga2::agent {
  $zones = hiera('icinga2::zones')
  $endpoints = hiera('icinga2::endpoints')
  $accept_config = hiera('icinga2::accept_config')
  $features = hiera('icinga2::features')

  include profile::icinga2::apt_config

  class {'::icinga2':
    confd    => false,
    features => $features,
  }

  class { 'icinga2::feature::api':
    accept_config   => $accept_config,
    accept_commands => true,
    endpoints       => $endpoints,
    zones           => $zones,
  }

  icinga2::object::zone { 'global-templates':
    global => true,
  }
}
