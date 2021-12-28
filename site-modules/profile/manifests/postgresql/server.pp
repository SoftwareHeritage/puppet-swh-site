# Install and configure a postgresql server
class profile::postgresql::server {

  $swh_base_directory = lookup('swh::base_directory')

  $postgres_pass = lookup('swh::deploy::db::postgres::password')
  $listen_addresses = lookup('swh::postgresql::listen_addresses').join(',')

  # allow access through credentials
  $network_accesses = lookup('swh::postgresql::network_accesses').map | $nwk | {
      "host all all ${nwk} md5"
  }
  $postgres_version = lookup('swh::postgresql::version')
  $postgres_port = lookup('swh::postgresql::port')
  $postgres_datadir_base = lookup('swh::postgresql::datadir_base')
  $postgres_datadir = lookup('swh::postgresql::datadir')
  $postgres_max_connections = lookup('swh::postgresql::max_connections')

  $ip_mask_allow_all_users = '0.0.0.0/0'
  file { [ $postgres_datadir_base,
      "${postgres_datadir_base}/${postgres_version}" ] :
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0655',
  }
  -> class { 'postgresql::server':
    ip_mask_allow_all_users => $ip_mask_allow_all_users,
    ipv4acls                => $network_accesses,
    postgres_password       => $postgres_pass,
    port                    => $postgres_port,
    listen_addresses        => [$listen_addresses],
    datadir                 => $postgres_datadir,
    needs_initdb            => true, # Needed because managed_repo is false and data_dir is redefined by us ¯\_(ツ)_/¯
    require                 => Class['profile::postgresql::apt_config'],
    pg_hba_conf_defaults    => false,  # see below for the actual default rules
    pg_hba_rules            => {
      # Supersedes the default rules installed by puppetlab-postgres, thus
      # allowing pgbouncer/pgsql connection to the postgres user
      'local access as postgres user'                 => {
        database    => 'all',
        user        => 'postgres',
        type        => 'local',
        auth_method => 'ident',
        order       => 1,
      },
      'local access to database with same name'       => {
        database    => 'all',
        user        => 'all',
        type        => 'local',
        auth_method => 'ident',
        order       => 2,
      },
      'allow localhost TCP access to postgresql user' => {
        database    => 'all',
        user        => 'postgres',
        type        => 'host',
        address     => '127.0.0.1/32',
        auth_method => 'md5',
        order       => 3,
      },
      'allow access to all users'                     => {
        database    => 'all',
        user        => 'all',
        type        => 'host',
        address     => $ip_mask_allow_all_users,
        auth_method => 'md5',
        order       => 100,
      },
      'allow access to ipv6 localhost'                => {
        database    => 'all',
        user        => 'all',
        type        => 'host',
        address     => '::1/128',
        auth_method => 'md5',
        order       => 101,
      }
    },
  }

  postgresql::server::config_entry{'max_connections':
      ensure => present,
      value  => $postgres_max_connections,
  }

  postgresql::server::config_entry{'shared_preload_libraries':
      ensure => present,
      value  => 'pg_stat_statements',
  }

  # read-only user
  $guest = 'guest'
  postgresql::server::role { $guest:
    password_hash => postgresql::postgresql_password($guest, 'guest'),
    require       => Class['postgresql::server']
  }

  $dbs = lookup('swh::dbs')
  each($dbs) | $db_type, $db_config | {
    # db_type in {storage, indexer, scheduler, etc...}
    $db_pass = pick(
      $db_config['password'],
      lookup("swh::deploy::${db_type}::db::password", {'default_value' => undef})
    )
    $db_name = $db_config['name']
    $db_user = $db_config['user']

    postgresql::server::db { $db_name:
      user     => $db_user,
      password => $db_pass,
      owner    => $db_user,
      require  => Class['postgresql::server']
    }

    # guest user has read access on tables
    postgresql::server::database_grant { $db_name:
      privilege => 'connect',
      db        => $db_name,
      role      => $guest,
      require   => Postgresql::Server::Db[$db_name]
    }
  }
}
