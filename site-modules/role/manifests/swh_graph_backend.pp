# SWH graph backend server
class role::swh_graph_backend inherits role::swh_base {
  include profile::docker
  include profile::megacli
  include profile::swh::deploy::graph
}
