# Manage a pgbouncer server
class profile::pgbouncer {
  $config_params = lookup('pgbouncer::config_params')
  $userlist = lookup('pgbouncer::userlist')
  $databases = lookup('pgbouncer::databases')

  # Need format manipulation (expected format in pgbouncer class is {key,
  # value} with no nested data)
  $listen_addr = join($config_params['listen_addr'], ',')
  $admin_users = join($config_params['admin_users'], ',')

  $expected_config_params = merge($config_params, {
    listen_addr => $listen_addr,
    admin_users => $admin_users,
  })

  class {'::pgbouncer':
    config_params => $expected_config_params,
    userlist      => $userlist,
    databases     => $databases,
  }
}
