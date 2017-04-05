# Deployment for swh-indexer-ctags

class profile::swh::deploy::worker::swh_indexer_ctags {
  include ::profile::swh::deploy::indexer

  $concurrency = hiera('swh::deploy::worker::swh_indexer::ctags::concurrency')
  $loglevel = hiera('swh::deploy::worker::swh_indexer::ctags::loglevel')
  $task_broker = hiera('swh::deploy::worker::swh_indexer::ctags::task_broker')

  $config_file = '/etc/softwareheritage/indexer/ctags.yml'
  $config = hiera('swh::deploy::worker::swh_indexer::ctags::config')

  $objstorage_config = hiera('swh::azure_objstorage::config')
  $merged_config = merge($config, {'objstorage' => $objstorage_config})

  $task_modules = ['swh.indexer.tasks']
  $task_queues = ['swh_indexer_content_ctags']

  ::profile::swh::deploy::worker::instance {'swh_indexer_ctags':
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
    content => inline_template("<%= @merged_config.to_yaml %>\n"),
  }
}
