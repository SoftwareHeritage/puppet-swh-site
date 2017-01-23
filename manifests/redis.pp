# Install and configure local redis server
class profile::redis {
  $redis_bind = hiera('redis::server::bind')
  $redis_port = hiera('redis::server::port')
  $redis_password = hiera('redis::server::password')

  class {'::redis':
    bind        => $redis_bind,
    port        => $redis_port,
    requirepass => $redis_password,
  }
}
