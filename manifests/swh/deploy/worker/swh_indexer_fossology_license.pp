# Deployment for swh-indexer-fossology-license

class profile::swh::deploy::worker::swh_indexer_fossology_license {
  include ::profile::swh::deploy::indexer

  $concurrency = hiera('swh::deploy::worker::swh_indexer::fossology_license::concurrency')
  $loglevel = hiera('swh::deploy::worker::swh_indexer::fossology_license::loglevel')
  $task_broker = hiera('swh::deploy::worker::swh_indexer::fossology_license::task_broker')

  $config_file = '/etc/softwareheritage/indexer/fossology_license.yml'
  $config = hiera('swh::deploy::worker::swh_indexer::fossology_license::config')

  $task_modules = ['swh.indexer.tasks']
  $task_queues = ['swh_indexer_content_fossology_license']

  ::profile::swh::deploy::worker::instance {'swh_indexer_fossology_license':
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
