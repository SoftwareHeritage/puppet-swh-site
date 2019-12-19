# Deployment of a cassandra node
class role::swh_cassandra_node inherits role::swh_base {
  include profile::puppet::agent

  include profile::cassandra::node
}
