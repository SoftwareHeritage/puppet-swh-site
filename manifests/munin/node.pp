# Munin node class
class profile::munin::node {
  $munin_node_allow = hiera('munin::node::allow')

  class { '::munin::node':
    allow   => $munin_node_allow,
    address => ip_for_network('192.168.100.0/24')
  }
}
