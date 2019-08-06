class profile::postgresql::server {
  class { 'postgresql::globals':
    encoding            => 'UTF-8',
    locale              => 'en_US.UTF-8',
    manage_package_repo => true,
    version             => '11',
  }

  $postgres_pass = lookup('swh::deploy::db::postgres::password')

  class { 'postgresql::server':
    ip_mask_deny_postgres_user => '0.0.0.0/32',
    ip_mask_allow_all_users    => '0.0.0.0/0',
    ipv4acls                   => ['hostssl all guest 192.168.128.0/24 cert'],
    postgres_password          => $postgres_pass,
    port                       => 5433,
  }

  $guest = 'guest'
  postgresql::server::role { $guest:
    password_hash => postgresql_password($guest, 'guest'),
  }

  $dbs = lookup('swh::dbs')
  each($dbs) | $db_type, $db_config | {
    # db_type in {storage, indexer, scheduler, etc...}
    $db_pass = lookup("swh::deploy::db::${db_type}::password")
    $db_name = $db_config['name']
    $db_user = $db_config['user']

    postgresql::server::db { $db_name:
      user     => $db_user,
      password => $db_pass,
      owner    => $db_user
    }

    # guest user has read access on tables
    postgresql::server::table_grant { $db_name:
      privilege   => 'select',
      db          => $db_name,
      role        => $guest,
      table       => 'all',
    }
  }
}
