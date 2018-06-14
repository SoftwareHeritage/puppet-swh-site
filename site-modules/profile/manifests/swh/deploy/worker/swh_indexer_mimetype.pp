# Deployment for swh-indexer-mimetype

class profile::swh::deploy::worker::swh_indexer_mimetype {
  include ::profile::swh::deploy::indexer

  $concurrency = lookup('swh::deploy::worker::swh_indexer::mimetype::concurrency')
  $loglevel = lookup('swh::deploy::worker::swh_indexer::mimetype::loglevel')
  $task_broker = lookup('swh::deploy::worker::swh_indexer::mimetype::task_broker')

  $config_file = '/etc/softwareheritage/indexer/mimetype.yml'
  $config = lookup('swh::deploy::worker::swh_indexer::mimetype::config')

  $task_modules = ['swh.indexer.tasks']
  $task_queues = ['swh_indexer_content_mimetype']

  Package[$::profile::swh::deploy::indexer::packages] ~> ::profile::swh::deploy::worker::instance {'swh_indexer_mimetype':
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
