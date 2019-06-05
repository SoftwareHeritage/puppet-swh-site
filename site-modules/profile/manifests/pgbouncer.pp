# Manage a pgbouncer server
class profile::pgbouncer {
  $config_params = lookup('pgbouncer::config_params')
  $userlist = lookup('pgbouncer::userlist')
  $databases = lookup('pgbouncer::databases')

  class {'::pgbouncer':
    config_params => $config_params,
    userlist      => $userlist,
    databases     => $databases,
  }
}
