# An icinga master host
class profile::icinga2::master {
  $zonename = hiera('icinga2::master::zonename')
  $features = hiera('icinga2::features')
  $icinga2_network = hiera('icinga2::network')

  include profile::icinga2::apt_config

  class {'::icinga2':
    confd     => false,
    features  => $features,
    constants => {
      'ZoneName' => $zonename,
    },
  }

  class { '::icinga2::feature::api':
    accept_commands => true,
  }

  @@::icinga2::object::endpoint {$::fqdn:
    target => "/etc/icinga2/zones.d/${::fqdn}.conf",
  }

  @@::icinga2::object::zone {$zonename:
    endpoints => [$::fqdn],
    target    => "/etc/icinga2/zones.d/${::fqdn}.conf",
  }

  @@::icinga2::object::host {$::fqdn:
    address => ip_for_network($icinga2_network),
    target  => "/etc/icinga2/zones.d/${::fqdn}.conf",
  }

  ::Icinga2::Object::Host <<| |>>
  ::Icinga2::Object::Endpoint <<| |>>
  ::Icinga2::Object::Zone <<| |>>

  ::icinga2::object::zone { 'global-templates':
    global => true,
  }
}
