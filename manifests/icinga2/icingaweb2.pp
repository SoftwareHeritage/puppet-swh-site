# Icinga web 2 configuration
class profile::icinga2::icingaweb2 {
  $icinga2_db_username = hiera('icinga2::master::db::username')
  $icinga2_db_password = hiera('icinga2::master::db::password')
  $icinga2_db_database = hiera('icinga2::master::db::database')

  $icingaweb2_db_username = hiera('icinga2::icingaweb2::db::username')
  $icingaweb2_db_password = hiera('icinga2::icingaweb2::db::password')
  $icingaweb2_db_database = hiera('icinga2::icingaweb2::db::database')

  include profile::icinga2::apt_config

  class {'::icingaweb2':
    manage_repo    => false,
    manage_package => true,
    import_schema  => true,
    db_type        => 'pgsql',
    db_host        => 'localhost',
    db_port        => 5432,
    db_username    => $icingaweb2_db_username,
    db_password    => $icingaweb2_db_username,
    require        => Postgresql::Server::Db[$icingaweb2_db_database],
  }

  ::postgresql::server::db {$icingaweb2_db_database:
    user     => $icingaweb2_db_username,
    password => postgresql_password($icingaweb2_db_username, $icingaweb2_db_password),
  }

  class {'::icingaweb2::module::monitoring':
    ido_host          => 'localhost',
    ido_db_name       => $icinga2_db_database,
    ido_db_username   => $icinga2_db_username,
    ido_db_password   => $icinga2_db_password,
    commandtransports => {
      icinga2 => {
        transport => 'local',
        path      => '/var/run/icinga2/cmd/icinga2.cmd',
      }
    }
  }

  include ::icingaweb2::module::doc
}
