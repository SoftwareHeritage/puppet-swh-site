# Icinga2 agent configuration
class profile::icinga2::agent {
  $features = hiera('icinga2::features')
  $icinga2_network = hiera('icinga2::network')
  $hiera_host_vars = hiera_hash('icinga2::host::vars')

  $parent_zone = hiera('icinga2::parent_zone')
  $parent_endpoints = hiera('icinga2::parent_endpoints')

  $local_host_vars = {
    disks => hash(flatten(
      $::mounts.map |$mount| {
        ["disk ${mount}", {disk_partitions => $mount}]
      },
    )),
  }

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
    target => "/etc/icinga2/zones.d/${parent_zone}/${::fqdn}.conf",
  }

  @@::icinga2::object::zone {$::fqdn:
    endpoints => [$::fqdn],
    parent    => $parent_zone,
    target    => "/etc/icinga2/zones.d/${parent_zone}/${::fqdn}.conf",
  }

  @@::icinga2::object::host {$::fqdn:
    address       => ip_for_network($icinga2_network),
    display_name  => $::fqdn,
    check_command => 'hostalive',
    vars          => deep_merge($local_host_vars, $hiera_host_vars),
    target        => "/etc/icinga2/zones.d/${parent_zone}/${::fqdn}.conf",
  }

  icinga2::object::zone { 'global-templates':
    global => true,
  }

  include profile::icinga2::objects::agent_checks
}
