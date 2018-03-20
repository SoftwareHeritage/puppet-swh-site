# Zookeeper cluster member profile

class profile::zookeeper {
  class {'::zookeeper':
    servers       => lookup('zookeeper::servers', Hash),
    datastore     => lookup('zookeeper::datastore'),
    client_port   => lookup('zookeeper::client_port'),
    election_port => lookup('zookeeper::election_port'),
    leader_port   => lookup('zookeeper::leader_port'),
  }
}
