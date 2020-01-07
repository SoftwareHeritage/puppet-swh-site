# Deployment of a cassandra node
class role::swh_cassandra_node inherits role::swh_base {
  include profile::cassandra::node
}
