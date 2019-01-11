# Deployment for swh-indexer-rehash

class profile::swh::deploy::worker::swh_indexer_rehash {
  include ::profile::swh::deploy::indexer

  $concurrency = lookup('swh::deploy::worker::swh_indexer::rehash::concurrency')
  $loglevel = lookup('swh::deploy::worker::swh_indexer::rehash::loglevel')
  $task_broker = lookup('swh::deploy::worker::swh_indexer::rehash::task_broker')

  $config_file = '/etc/softwareheritage/indexer/rehash.yml'
  $config = lookup('swh::deploy::worker::swh_indexer::rehash::config')

  $task_modules = ['swh.indexer.tasks']
  $task_queues = ['swh_indexer_content_rehash']

  Package[$::profile::swh::deploy::base_indexer::packages] ~> ::profile::swh::deploy::worker::instance {'swh_indexer_rehash':
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
