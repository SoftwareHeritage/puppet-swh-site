# Deployment for swh-indexer-fossology-license

class profile::swh::deploy::worker::swh_indexer_fossology_license {
  include ::profile::swh::deploy::indexer

  $concurrency = lookup('swh::deploy::worker::swh_indexer::fossology_license::concurrency')
  $loglevel = lookup('swh::deploy::worker::swh_indexer::fossology_license::loglevel')
  $task_broker = lookup('swh::deploy::worker::swh_indexer::fossology_license::task_broker')

  $config_file = lookup('swh::deploy::worker::swh_indexer::fossology_license::config_file')
  $config_directory = lookup('swh::conf_directory')
  $config_path = "${config_directory}/${config_file}"
  $config = lookup('swh::deploy::worker::swh_indexer::fossology_license::config')

  $task_modules = ['swh.indexer.tasks']
  $task_queues = ['swh_indexer_content_fossology_license', 'swh_indexer_content_fossology_license_range']

  Package[$::profile::swh::deploy::base_indexer::packages] ~> ::profile::swh::deploy::worker::instance {'swh_indexer_fossology_license':
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
