# Deployment for swh-storage-archiver
class profile::swh::deploy::worker::swh_storage_archiver {
  include ::profile::swh::deploy::archiver

  $concurrency = hiera('swh::deploy::worker::swh_storage_archiver::concurrency')
  $loglevel = hiera('swh::deploy::worker::swh_storage_archiver::loglevel')
  $task_broker = hiera('swh::deploy::worker::swh_storage_archiver::task_broker')

  $config_file = hiera('swh::deploy::worker::swh_storage_archiver::conf_file')
  $config = hiera('swh::deploy::worker::swh_storage_archiver::config')

  $storages_config = hiera_array('swh::deploy::worker::swh_storage_archiver::storages')
  $merged_config = merge($config, {'storages' => $storages_config})

  $task_modules = ['swh.storage.archiver.tasks']
  $task_queues = ['swh_storage_archive_worker']

  ::profile::swh::deploy::worker::instance {'swh_storage_archiver':
    ensure       => present,
    concurrency  => $concurrency,
    loglevel     => $loglevel,
    task_broker  => $task_broker,
    task_modules => $task_modules,
    task_queues  => $task_queues,
    require      => [
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
