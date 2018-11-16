# Deployment for swh-indexer-revision-metadata

class profile::swh::deploy::worker::swh_indexer_revision_metadata {
  include ::profile::swh::deploy::indexer

  $concurrency = lookup('swh::deploy::worker::swh_indexer::revision_metadata::concurrency')
  $loglevel = lookup('swh::deploy::worker::swh_indexer::revision_metadata::loglevel')
  $task_broker = lookup('swh::deploy::worker::swh_indexer::revision_metadata::task_broker')

  $config_file = '/etc/softwareheritage/indexer/revision_metadata.yml'
  $config = lookup('swh::deploy::worker::swh_indexer::revision_metadata::config')

  $task_modules = ['swh.indexer.tasks']
  $task_queues = ['swh_indexer_revision_metadata']

  Package[$::profile::swh::deploy::indexer::packages] ~> ::profile::swh::deploy::worker::instance {'swh_indexer_revision_metadata':
    ensure       => present,
    concurrency  => $concurrency,
    loglevel     => $loglevel,
    task_broker  => $task_broker,
    task_modules => $task_modules,
    task_queues  => $task_queues,
    require      => [
      Class['profile::swh::deploy::indexer'],
      Class['profile::swh::deploy::objstorage_cloud'],
      File[$config_file],
    ],
  }

  file {$config_file:
    ensure  => 'present',
    owner   => 'swhworker',
    group   => 'swhdev',
    # Contains passwords
    mode    => '0640',
    content => inline_template("<%= @config.to_yaml %>\n"),
  }
}

