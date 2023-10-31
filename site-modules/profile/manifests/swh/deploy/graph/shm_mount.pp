# Mount the graph export in shared memory to avoid having to mmap it from disk all the time
class profile::swh::deploy::graph::shm_mount {
  $shm_path = '/dev/shm/swh-graph/default'
  $compressed_graph_path = lookup('swh::deploy::graph::compressed_path')

  $files_to_copy = lookup(
    'swh::deploy::graph::shm_mount::files_to_copy',
    Array[String],
    'first',
    [
      'graph.graph',
      'graph-transposed.graph',
    ])

  $service_name = 'swh-graph-shm-mount'
  $unit_name = "${service_name}.service"

  $user = $profile::swh::deploy::graph::user
  $group = $profile::swh::deploy::graph::group
  ::systemd::unit_file {$unit_name:
    ensure  => present,
    content => template("profile/swh/deploy/graph/${unit_name}.erb"),
    mode    => '0644',
  } ~> service {$service_name:
    ensure => 'running',
    enable => true,
  }
}
