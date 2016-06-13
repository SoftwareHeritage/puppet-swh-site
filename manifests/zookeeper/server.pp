# Zookeeper cluster member profile

class profile::zookeeper::server {
  include ::profile::zookeeper::client
  class {'::zookeeper::server':}
}
