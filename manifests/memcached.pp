# Install and configure local memcached server
class profile::memcached {
  $memcached_bind = hiera('memcached::server::bind')
  $memcached_port = hiera('memcached::server::port')
  $memcached_memory = hiera('memcached::server::max_memory')

  class {'::memcached':
    listen_ip  => $memcached_bind,
    tcp_port   => $memcached_port,
    max_memory => $memcached_max_memory,
  }
}
