class role::rancher_node_with_multipath inherits role::rancher_node {
  include profile::megacli
  include profile::multipath
}
