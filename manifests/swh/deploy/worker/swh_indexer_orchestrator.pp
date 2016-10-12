# Deployment for swh-indexer

class profile::swh::deploy::worker::swh_indexer_orchestrator {

  include ::profile::swh::deploy::indexer

  $concurrency = hiera('swh::deploy::worker::swh_indexer::orchestrator::concurrency')
  $loglevel = hiera('swh::deploy::worker::swh_indexer::orchestrator::loglevel')
  $task_broker = hiera('swh::deploy::worker::swh_indexer::orchestrator::task_broker')

  $config_file = '/etc/softwareheritage/indexer/orchestrator.yml'
  $config = hiera('swh::deploy::worker::swh_indexer::orchestrator::config')

  $task_modules = ['swh.indexer.tasks']
  $task_queues = ['swh_indexer_orchestrator_content_all']

  ::profile::swh::deploy::worker::instance {'swh_indexer_orchestrator':
    ensure       => present,
    concurrency  => $concurrency,
    loglevel     => $loglevel,
    task_broker  => $task_broker,
    task_modules => $task_modules,
    task_queues  => $task_queues,
    require      => [
      Class['profile::swh::deploy::indexer'],
      File[$config_file],
    ],
  }

  file {$config_file:
    ensure  => 'present',
    owner   => 'swhworker',
    group   => 'swhworker',
    mode    => '0644',
    content => inline_template('<%= @config.to_yaml %>'),
  }
}
