# Munin node class
class profile::munin::node {
  $munin_node_allow = lookup('munin::node::allow')
  $munin_node_network = lookup('munin::node::network')
  $munin_node_plugins_disable = lookup('munin::node::plugins::disable', Array, 'unique')
  $munin_node_plugins_enable = lookup('munin::node::plugins::enable', Array, 'unique')

  class { '::munin::node':
    allow        => $munin_node_allow,
    address      => ip_for_network($munin_node_network),
    bind_address => ip_for_network($munin_node_network),
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

  file_line { 'disable munin-node cron mail':
    ensure  => present,
    path    => '/etc/cron.d/munin-node',
    line    => 'MAILTO=""',
    match   => '^MAILTO=',
    require => Package['munin-node'],
  }
}
