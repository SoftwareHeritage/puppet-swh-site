# Deployment for swh-provenance-cache
class profile::swh::deploy::worker::swh_provenance_cache {
  include ::profile::swh::deploy::loader

  $concurrency = hiera('swh::deploy::worker::swh_provenance_cache::concurrency')
  $loglevel = hiera('swh::deploy::worker::swh_provenance_cache::loglevel')
  $task_broker = hiera('swh::deploy::worker::swh_provenance_cache::task_broker')

  $config_file = '/etc/softwareheritage/storage/provenance_cache.yml'
  $config = hiera('swh::deploy::worker::swh_provenance_cache::config')

  $task_modules = ['swh.storage.provenance.tasks']
  $task_queues = [
    'swh_populate_cache_content_revision',
    'swh_populate_cache_revision_origin'
  ]

  $packages = ['python3-swh.storage.provenance']

  package {$packages:
    ensure => 'installed',
  }

  ::profile::swh::deploy::worker::instance {'provenance-cache':
    ensure       => present,
    concurrency  => $concurrency,
    loglevel     => $loglevel,
    task_broker  => $task_broker,
    task_modules => $task_modules,
    task_queues  => $task_queues,
    require      => [
      Package[$packages],
      File[$config_file],
    ],
  }

  file {$config_file:
    ensure  => 'present',
    owner   => 'swhworker',
    group   => 'swhdev',
    # Contains password
    mode    => '0640',
    content => inline_template('<%= @config.to_yaml %>\n'),
  }
}
