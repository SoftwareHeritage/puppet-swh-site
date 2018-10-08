# Icinga2 agent configuration
class profile::icinga2::agent {
  $features = lookup('icinga2::features')
  $icinga2_network = lookup('icinga2::network')
  $hiera_host_vars = lookup('icinga2::host::vars', Hash, 'deep')

  $parent_zone = lookup('icinga2::parent_zone')
  $parent_endpoints = lookup('icinga2::parent_endpoints')

  include profile::icinga2::objects::agent_checks

  $check_mounts = $::mounts.filter |$mount| {
    $mount !~ /^\/srv\/containers/
  }

  $local_host_vars = {
    disks => hash(flatten(
      $check_mounts.map |$mount| {
        ["disk ${mount}", {disk_partitions => $mount}]
      },
    )),
    plugins => keys($profile::icinga2::objects::agent_checks::plugins),
  }

  class {'::icinga2':
    confd    => true,
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
    host   => ip_for_network($icinga2_network),
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

  file {['/etc/icinga2/conf.d']:
    ensure  => directory,
    owner   => 'nagios',
    group   => 'nagios',
    mode    => '0755',
    purge   => true,
    recurse => true,
    tag     => 'icinga2::config::file',
  }
}
