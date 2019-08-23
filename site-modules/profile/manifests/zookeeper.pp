# Zookeeper cluster member profile

class profile::zookeeper {
  $zookeeper_clusters = lookup('zookeeper::clusters', Hash)

  $zookeeper_cluster = $zookeeper_clusters.filter |$cluster, $servers| {
    member($servers.values(), $::swh_hostname['internal_fqdn'])
  }.keys()[0]

  $zookeeper_servers = $zookeeper_clusters[$zookeeper_cluster]

  $zookeeper_id = $zookeeper_servers.filter |$id, $hostname| {
    $hostname == $::swh_hostname['internal_fqdn']
  }.keys()[0]

  class {'::zookeeper':
    servers       => $zookeeper_servers,
    datastore     => lookup('zookeeper::datastore'),
    client_port   => lookup('zookeeper::client_port'),
    election_port => lookup('zookeeper::election_port'),
    leader_port   => lookup('zookeeper::leader_port'),
    id            => $zookeeper_id,
  }
}
