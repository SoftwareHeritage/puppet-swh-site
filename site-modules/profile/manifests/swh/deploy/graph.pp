# Deployment of graph (checks for now)

# FIXME: Graph is currently managed manually and running through a venv. At some point,
# adapt here to also install fully the graph from that manifest
class profile::swh::deploy::graph {

  $packages = ['python3-venv']
  package {$packages:
    ensure => 'present',
  }

  $user = lookup('swh::deploy::graph::user')
  $group = lookup('swh::deploy::graph::group')

  # install services from templates
  $services = [ {  # this matches the current status
    'name' => 'swhgraphshm',
    'status'  => 'present',
    'enable' => false,
  }, {
    'name' => 'swhgraphdev',
    'status'  => 'running',
    'enable' => true,
  }
  ]
  each($services) | $service | {
    $unit_name = "${service['name']}.service"

    # template uses:
    # $user
    # $group
    ::systemd::unit_file {$unit_name:
      ensure  => present,
      content => template("profile/swh/deploy/graph/${unit_name}.erb"),
      mode    => '0644',
    } ~> service {$service['name']:
      ensure => $service['status'],
      enable => $service['enable'],
    }
  }
}
