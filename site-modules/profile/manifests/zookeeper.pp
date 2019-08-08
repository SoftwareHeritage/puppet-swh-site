# Zookeeper cluster member profile

class profile::zookeeper {
  $zookeeper_servers = lookup('zookeeper::servers', Hash)

  $zookeeper_ids = $zookeeper_servers.filter |$id, $hostname| {
    $hostname == $::swh_hostname['internal_fqdn']
  }.keys

  class {'::zookeeper':
    servers       => $zookeeper_servers,
    datastore     => lookup('zookeeper::datastore'),
    client_port   => lookup('zookeeper::client_port'),
    election_port => lookup('zookeeper::election_port'),
    leader_port   => lookup('zookeeper::leader_port'),
    id            => $zookeeper_ids[0],
  }
}
