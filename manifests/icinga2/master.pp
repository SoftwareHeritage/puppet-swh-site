# An icinga master host
class profile::icinga2::master {
  $zonename = hiera('icinga2::master::zonename')
  $features = hiera('icinga2::features')
  $icinga2_network = hiera('icinga2::network')

  $icinga2_db_username = hiera('icinga2::master::db::username')
  $icinga2_db_password = hiera('icinga2::master::db::password')
  $icinga2_db_database = hiera('icinga2::master::db::database')

  include profile::icinga2::apt_config
  include profile::icinga2::objects

  include ::postgresql::server

  ::postgresql::server::db {$icinga2_db_database:
    user     => $icinga2_db_username,
    password => postgresql_password($icinga2_db_username, $icinga2_db_password)
  }

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

  class { '::icinga2::feature::idopgsql':
    user          => $icinga2_db_username,
    password      => $icinga2_db_password,
    database      => $icinga2_db_database,
    import_schema => true,
    require       => Postgresql::Server::Db[$icinga2_db_database],
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
