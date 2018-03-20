# Zookeeper cluster member profile

class profile::zookeeper {
  class {'::zookeeper':
    servers       => lookup('zookeeper::servers', Hash),
    datastore     => lookup('zookeeper::datastore'),
    election_port => lookup('zookeeper::election_port'),
    leader_port   => lookup('zookeeper::election_port'),
  }
}
