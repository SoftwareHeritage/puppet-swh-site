# Deployment for swh-reader-git
class profile::swh::deploy::worker::swh_reader_git {
  include ::profile::swh::deploy::base_loader_git
  include ::profile::swh::deploy::worker::swh_storage_archiver_azure

  $concurrency = hiera('swh::deploy::worker::swh_reader_git::concurrency')
  $loglevel = hiera('swh::deploy::worker::swh_reader_git::loglevel')
  $task_broker = hiera('swh::deploy::worker::swh_reader_git::task_broker')

  $config_file = '/etc/softwareheritage/loader/git-remote-reader.yml'
  $config = hiera('swh::deploy::worker::swh_reader_git::config')

  $task_modules = ['swh.loader.git.tasks']
  $task_queues = ['swh_reader_git']

  ::profile::swh::deploy::worker::instance {'swh_reader_git':
    ensure       => present,
    concurrency  => $concurrency,
    loglevel     => $loglevel,
    task_broker  => $task_broker,
    task_modules => $task_modules,
    task_queues  => $task_queues,
    require      => [
      Class['profile::swh::deploy::base_loader_git'],
      Class['profile::swh::deploy::worker::swh_storage_archiver_azure'],
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
