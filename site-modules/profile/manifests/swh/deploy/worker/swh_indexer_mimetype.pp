# Deployment for swh-indexer-mimetype

class profile::swh::deploy::worker::swh_indexer_mimetype {
  include ::profile::swh::deploy::indexer

  $concurrency = lookup('swh::deploy::worker::swh_indexer::mimetype::concurrency')
  $loglevel = lookup('swh::deploy::worker::swh_indexer::mimetype::loglevel')
  $task_broker = lookup('swh::deploy::worker::swh_indexer::mimetype::task_broker')

  $config_file = lookup('swh::deploy::worker::swh_indexer::mimetype::config_file')
  $config_directory = lookup('swh::conf_directory')
  $config_path = "${config_directory}/${config_file}"
  $config = lookup('swh::deploy::worker::swh_indexer::mimetype::config')

  $task_modules = ['swh.indexer.tasks']
  $task_queues = ['swh_indexer_content_mimetype', 'swh_indexer_content_mimetype_range']

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
      File[$config_path],
    ],
  }

  file {$config_path:
    ensure  => 'present',
    owner   => 'swhworker',
    group   => 'swhdev',
    # Contains passwords
    mode    => '0640',
    content => inline_template("<%= @config.to_yaml %>\n"),
  }
}
