# An icinga master host
class profile::icinga2::master {
  $zonename = lookup('icinga2::master::zonename')
  $features = lookup('icinga2::features')
  $icinga2_network = lookup('icinga2::network')

  $hiera_host_vars = lookup('icinga2::host::vars', Hash, 'deep')

  $icinga2_db_username = lookup('icinga2::master::db::username')
  $icinga2_db_password = lookup('icinga2::master::db::password')
  $icinga2_db_database = lookup('icinga2::master::db::database')

  include profile::icinga2::objects
  include profile::icinga2::objects::agent_checks

  $local_host_vars = {
    disks => hash(flatten(
      $::mounts.map |$mount| {
        ["disk ${mount}", {disk_partitions => $mount}]
      },
      )),
    plugins => keys($profile::icinga2::objects::agent_checks::plugins),
  }

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
    pki             => 'puppet',
    accept_commands => true,
    zones           => {
      $zonename => {
        endpoints => ['NodeName'],
      }
    },
  }

  class { '::icinga2::feature::idopgsql':
    user          => $icinga2_db_username,
    password      => $icinga2_db_password,
    database      => $icinga2_db_database,
    import_schema => true,
    require       => Postgresql::Server::Db[$icinga2_db_database],
  }

  @@::icinga2::object::host {$::fqdn:
    address       => ip_for_network($icinga2_network),
    display_name  => $::fqdn,
    check_command => 'hostalive',
    vars          => deep_merge($local_host_vars, $hiera_host_vars),
    target        => "/etc/icinga2/zones.d/${zonename}/${::fqdn}.conf",
  }

  ::icinga2::object::service {'check-deposit':
    import           => ['generic-service-check-e2e'],
    apply            => true,
    check_command    => 'check-deposit-cmd',
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
    ensure  => directory,
    owner   => 'nagios',
    group   => 'nagios',
    mode    => '0755',
    tag     => 'icinga2::config::file',
    recurse => true,
    purge   => true,
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
