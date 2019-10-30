# SWH graph backend server
class role::swh_graph_backend inherits role::swh_base {
  include profile::puppet::agent

  include profile::docker
}
