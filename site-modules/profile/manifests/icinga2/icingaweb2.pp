# Icinga web 2 configuration
class profile::icinga2::icingaweb2 {
  $icinga2_db_username = lookup('icinga2::master::db::username')
  $icinga2_db_password = lookup('icinga2::master::db::password')
  $icinga2_db_database = lookup('icinga2::master::db::database')

  $icingaweb2_db_username = lookup('icinga2::icingaweb2::db::username')
  $icingaweb2_db_password = lookup('icinga2::icingaweb2::db::password')
  $icingaweb2_db_database = lookup('icinga2::icingaweb2::db::database')
  $icingaweb2_protected_customvars = lookup('icinga2::icingaweb2::protected_customvars')

  include profile::icinga2::apt_config
  include profile::icinga2::icingaweb2::vhost

  class {'::icingaweb2':
    manage_repo    => false,
    manage_package => true,
    import_schema  => true,
    db_type        => 'pgsql',
    db_host        => 'localhost',
    db_port        => 5432,
    db_username    => $icingaweb2_db_username,
    db_password    => $icingaweb2_db_password,
    require        => Postgresql::Server::Db[$icingaweb2_db_database],
  }

  # Icingaweb2 modules

  ::postgresql::server::db {$icingaweb2_db_database:
    user     => $icingaweb2_db_username,
    password => postgresql::postgresql_password($icingaweb2_db_username, $icingaweb2_db_password),
  }

  class {'::icingaweb2::module::monitoring':
    ido_type             => 'pgsql',
    ido_host             => 'localhost',
    ido_port             => 5432,
    ido_db_name          => $icinga2_db_database,
    ido_db_username      => $icinga2_db_username,
    ido_db_password      => $icinga2_db_password,
    protected_customvars => join($icingaweb2_protected_customvars, ', '),
    commandtransports    => {
      icinga2 => {
        transport => 'local',
        path      => '/var/run/icinga2/cmd/icinga2.cmd',
      }
    }
  }

  include ::icingaweb2::module::doc

  # Icingaweb2 permissions
  ::icingaweb2::config::role {'guest':
    users       => 'guest',
    permissions => 'module/monitoring',
  }

  ::icingaweb2::config::role {'icinga':
    users       => 'icinga',
    permissions => '*',
  }
}
