# Zookeeper cluster client class

class profile::zookeeper::client {
  class {'::zookeeper':
    hosts    => hiera_hash('zookeeper::cluster::hosts'),
    data_dir => hiera('zookeeper::data_dir'),
  }
}
