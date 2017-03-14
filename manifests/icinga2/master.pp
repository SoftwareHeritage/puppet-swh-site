# An icinga master host
class profile::icinga2::master {
  $zonename = hiera('icinga2::master::zonename')
  $features = hiera('icinga2::features')
  $icinga2_network = hiera('icinga2::network')

  $icinga2_host_vars = hiera_hash('icinga2::host::vars')

  $icinga2_db_username = hiera('icinga2::master::db::username')
  $icinga2_db_password = hiera('icinga2::master::db::password')
  $icinga2_db_database = hiera('icinga2::master::db::database')

  include profile::icinga2::objects

  include ::postgresql::server

  ::postgresql::server::db {$icinga2_db_database:
    user     => $icinga2_db_username,
    password => postgresql_password($icinga2_db_username, $icinga2_db_password)
  }

  class {'::icinga2':
    confd     => true,
    features  => $features,
    constants => {
      'ZoneName' => $zonename,
    },
  }

  class { '::icinga2::feature::api':
    accept_commands => true,
    zones           => {},
    endpoints       => {},
  }

  class { '::icinga2::feature::idopgsql':
    user          => $icinga2_db_username,
    password      => $icinga2_db_password,
    database      => $icinga2_db_database,
    import_schema => true,
    require       => Postgresql::Server::Db[$icinga2_db_database],
  }

  @@::icinga2::object::endpoint {$::fqdn:
    target => "/etc/icinga2/zones.d/${zonename}/${::fqdn}.conf",
  }

  @@::icinga2::object::zone {$zonename:
    endpoints => [$::fqdn],
    target    => "/etc/icinga2/zones.d/${zonename}/${::fqdn}.conf",
  }

  @@::icinga2::object::host {$::fqdn:
    address       => ip_for_network($icinga2_network),
    display_name  => $::fqdn,
    check_command => 'hostalive',
    vars          => $icinga2_host_vars,
    target        => "/etc/icinga2/zones.d/${zonename}/${::fqdn}.conf",
  }

  ::Icinga2::Object::Host <<| |>>
  ::Icinga2::Object::Endpoint <<| |>>
  ::Icinga2::Object::Zone <<| |>>

  ::icinga2::object::zone { 'global-templates':
    global => true,
  }

  file {[
    '/etc/icinga2/zones.d/global-templates',
    "/etc/icinga2/zones.d/${zonename}",
  ]:
    ensure => directory,
    owner  => 'nagios',
    group  => 'nagios',
    mode   => '0755',
    tag    => 'icinga2::config::file',
  }

  file {'/etc/icinga2/conf.d':
    ensure  => directory,
    owner   => 'nagios',
    group   => 'nagios',
    mode    => '0755',
    purge   => true,
    recurse => true,
    tag     => 'icinga2::config::file',
  }
}
