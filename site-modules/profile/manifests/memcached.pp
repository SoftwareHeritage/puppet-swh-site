# Install and configure local memcached server
class profile::memcached {
  $memcached_bind = lookup('memcached::server::bind')
  $memcached_port = lookup('memcached::server::port')
  $memcached_memory = lookup('memcached::server::max_memory')

  class {'::memcached':
    listen     => $memcached_bind,
    tcp_port   => $memcached_port,
    max_memory => $memcached_memory,
  }
}
