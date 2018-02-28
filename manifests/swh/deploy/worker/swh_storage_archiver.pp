# Deployment for swh-storage-archiver
class profile::swh::deploy::worker::swh_storage_archiver {
  include ::profile::swh::deploy::archiver

  $concurrency = lookup('swh::deploy::worker::swh_storage_archiver::concurrency')
  $loglevel = lookup('swh::deploy::worker::swh_storage_archiver::loglevel')
  $task_broker = lookup('swh::deploy::worker::swh_storage_archiver::task_broker')

  $config_file = lookup('swh::deploy::worker::swh_storage_archiver::conf_file')
  $config = lookup('swh::deploy::worker::swh_storage_archiver::config')

  $task_modules = ['swh.archiver.tasks']
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
    content => inline_template("<%= @config.to_yaml %>\n"),
  }
}
