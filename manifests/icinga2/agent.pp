# Icinga2 agent configuration
class profile::icinga2::agent {
  $features = hiera('icinga2::features')
  $icinga2_network = hiera('icinga2::network')
  $parent_zone = hiera('icinga2::parent_zone')
  $parent_endpoints = hiera('icinga2::parent_endpoints')

  include profile::icinga2::apt_config

  class {'::icinga2':
    confd    => false,
    features => $features,
  }

  class { '::icinga2::feature::api':
    accept_config   => true,
    accept_commands => true,
    zones           => {
      'ZoneName' => {
        endpoints => ['NodeName'],
        parent    => $parent_zone,
      },
    },
  }

  create_resources('::icinga2::object::endpoint', $parent_endpoints)
  ::icinga2::object::zone {$parent_zone:
    endpoints => keys($parent_endpoints),
  }

  @@::icinga2::object::endpoint {$::fqdn:
    target => "/etc/icinga2/zones.d/${::fqdn}.conf",
  }

  @@::icinga2::object::zone {$::fqdn:
    endpoints => [$::fqdn],
    parent    => $parent_zone,
    target    => "/etc/icinga2/zones.d/${::fqdn}.conf",
  }

  @@::icinga2::object::host {$::fqdn:
    address => ip_for_network($icinga2_network),
    target  => "/etc/icinga2/zones.d/${::fqdn}.conf",
  }

  icinga2::object::zone { 'global-templates':
    global => true,
  }
}
