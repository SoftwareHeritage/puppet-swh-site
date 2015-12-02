# Munin node class
class profile::munin::node {
  $munin_node_allow = hiera('munin::node::allow')
  $munin_node_network = hiera('munin::node::network')
  $munin_node_plugins_disable = hiera_array('munin::node::plugins::disable')
  $munin_node_plugins_enable = hiera_array('munin::node::plugins::enable')

  class { '::munin::node':
    allow        => $munin_node_allow,
    address      => ip_for_network($munin_node_network),
    masterconfig => [
      '',
      '# The apt plugin doesn\'t graph by default. Let\'s make it.',
      'apt.graph yes',
      'apt.graph_category system',
      'apt.graph_vlabel Total Packages',
      '',
      '# Move the libvirt plugins to a spaceless category',
      'libvirt_blkstat.graph_category virtualization',
      'libvirt_cputime.graph_category virtualization',
      'libvirt_ifstat.graph_category virtualization',
      'libvirt_mem.graph_category virtualization',
    ],
  }

  munin::plugin { $munin_node_plugins_enable:
    ensure => link,
  }
  munin::plugin { $munin_node_plugins_disable:
    ensure => absent,
  }
}
