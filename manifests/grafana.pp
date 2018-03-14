class profile::grafana {
  $db = lookup('grafana::db::database')
  $db_username = lookup('grafana::db::username')
  $db_password = lookup('grafana::db::password')

  $config = lookup('grafana::config')

  include ::postgresql::server

  ::postgresql::server::db {$db:
    user     => $db_username,
    password => postgresql_password($db_username, $db_password),
  }

  class {'::grafana':
    install_method => 'repo',
    version        => 'latest',
    cfg            => $config + {
      database => {
        type     => 'postgres',
        host     => '127.0.0.1:5432',
        name     => $db,
        user     => $db_username,
        password => $db_password
      }
    }
  }

  contain profile::grafana::vhost
  contain profile::grafana::objects
}
