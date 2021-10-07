# Deployment for swh-lister
class profile::swh::deploy::worker::lister {
  $packages = ['python3-swh.lister', 'r-base-core', 'r-cran-jsonlite']

  package {$packages:
    ensure => present,
  }

  ::profile::swh::deploy::worker::instance {'lister':
    ensure           => present,
    send_task_events => true,
    require          => [
      Package['python3-swh.lister'],
    ],
    merge_policy     => 'first',  # do not merge configuration, take the first
                                  # encountered configuration
  }
}
