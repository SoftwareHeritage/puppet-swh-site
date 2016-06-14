# Kafka server profile

class profile::kafka::server {
  include ::profile::zookeeper::server

  class {'kafka':}

  class {'kafka::server':
    log_dirs         => hiera_array('kafka::log_dirs'),
    brokers          => hiera_hash('kafka::brokers'),
    zookeeper_hosts  => hiera_array('kafka::zookeeper::hosts'),
    zookeeper_chroot => hiera('kafka::zookeeper::chroot'),
  }
}
