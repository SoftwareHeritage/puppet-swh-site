# Deployment for swh-loader-git (archive)
class profile::swh::deploy::worker::swh_loader_git_archive {
  include ::profile::swh::deploy::base_loader_git

  $concurrency = hiera('swh::deploy::worker::swh_loader_git_archive::concurrency')
  $loglevel = hiera('swh::deploy::worker::swh_loader_git_archive::loglevel')
  $task_broker = hiera('swh::deploy::worker::swh_loader_git_archive::task_broker')

  $config_file = '/etc/softwareheritage/loader/archive-git-loader.yml'
  $config = hiera('swh::deploy::worker::swh_loader_git_archive::config')

  $task_modules = ['swh.loader.git.tasks']
  $task_queues = ['swh_loader_git_archive']

  ::profile::swh::deploy::worker::instance {'swh_loader_git_archive':
    ensure       => present,
    concurrency  => $concurrency,
    loglevel     => $loglevel,
    task_broker  => $task_broker,
    task_modules => $task_modules,
    task_queues  => $task_queues,
    require      => [
      Class['profile::swh::deploy::base_loader_git'],
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
