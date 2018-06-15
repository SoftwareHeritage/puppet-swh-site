# Deployment for swh-indexer

class profile::swh::deploy::worker::swh_indexer_orchestrator_text {

  include ::profile::swh::deploy::indexer

  $concurrency = lookup('swh::deploy::worker::swh_indexer::orchestrator_text::concurrency')
  $loglevel = lookup('swh::deploy::worker::swh_indexer::orchestrator_text::loglevel')
  $task_broker = lookup('swh::deploy::worker::swh_indexer::orchestrator_text::task_broker')

  $config_file = '/etc/softwareheritage/indexer/orchestrator_text.yml'
  $config = lookup('swh::deploy::worker::swh_indexer::orchestrator_text::config')

  $task_modules = ['swh.indexer.tasks']
  $task_queues = ['swh_indexer_orchestrator_content_text']

  Package[$::profile::swh::deploy::indexer::packages] ~> ::profile::swh::deploy::worker::instance {'swh_indexer_orchestrator_text':
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
    content => inline_template("<%= @config.to_yaml %>\n"),
  }
}
