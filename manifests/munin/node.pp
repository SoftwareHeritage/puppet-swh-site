# Munin node class
class profile::munin::node {
  $munin_node_allow = hiera('munin::node::allow')
  $munin_node_plugins_disable = hiera_array('munin::node::plugins::disable')
  $munin_node_plugins_enable = hiera_array('munin::node::plugins::enable')

  class { '::munin::node':
    allow   => $munin_node_allow,
    address => ip_for_network('192.168.100.0/24')
  }

  munin::plugin { $munin_node_plugins_enable:
    ensure => link,
  }
  munin::plugin { $munin_node_plugins_disable:
    ensure => absent,
  }
}
