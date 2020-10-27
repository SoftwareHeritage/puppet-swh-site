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
  $postgres_datadir = lookup('swh::postgresql::datadir')

  file { [ "${swh_base_directory}/postgresql",
      "${swh_base_directory}/postgresql/${postgres_version}" ] :
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0655',
  }
  -> class { 'postgresql::server':
    ip_mask_allow_all_users => '0.0.0.0/0',
    ipv4acls                => $network_accesses,
    postgres_password       => $postgres_pass,
    port                    => $postgres_port,
    listen_addresses        => [$listen_addresses],
    datadir                 => $postgres_datadir,
    needs_initdb            => true, # Needed because managed_repo is false and data_dir is redefined by us ¯\_(ツ)_/¯
    require                 => Class['profile::postgresql::apt_config']
  }

  $guest = 'guest'
  postgresql::server::role { $guest:
    password_hash => postgresql_password($guest, 'guest'),
    require       => Class['postgresql::server']
  }

  $dbs = lookup('swh::dbs')
  each($dbs) | $db_type, $db_config | {
    # db_type in {storage, indexer, scheduler, etc...}
    $db_pass = lookup("swh::deploy::${db_type}::db::password")
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
