# Kafka server profile

class profile::kafka::server {
  include ::profile::zookeeper::server

  class {'::kafka':}

  class {'::kafka::server':
    log_dirs         => lookup('kafka::log_dirs', Array, 'unique'),
    brokers          => lookup('kafka::brokers', Hash, 'deep'),
    zookeeper_hosts  => lookup('kafka::zookeeper::hosts', Array, 'unique'),
    zookeeper_chroot => lookup('kafka::zookeeper::chroot'),
  }
}
