# Deployment for swh-indexer-language

class profile::swh::deploy::worker::swh_indexer_language {
  include ::profile::swh::deploy::indexer

  $concurrency = hiera('swh::deploy::worker::swh_indexer::language::concurrency')
  $loglevel = hiera('swh::deploy::worker::swh_indexer::language::loglevel')
  $task_broker = hiera('swh::deploy::worker::swh_indexer::language::task_broker')

  $task_modules = ['swh.indexer.tasks']
  $task_queues = ['swh_indexer_content_language']

  ::profile::swh::deploy::worker::instance {'swh_indexer_language':
    ensure       => present,
    concurrency  => $concurrency,
    loglevel     => $loglevel,
    task_broker  => $task_broker,
    task_modules => $task_modules,
    task_queues  => $task_queues,
    require      => [
      Class['profile::swh::deploy::indexer'],
    ],
  }
}
