# Zookeeper cluster client class

class profile::zookeeper::client {
  class {'::zookeeper':
    hosts    => lookup('zookeeper::hosts', Hash, 'deep'),
    data_dir => lookup('zookeeper::data_dir'),
  }
}
