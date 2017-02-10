# Deployment for swh-loader-git (disk)
class profile::swh::deploy::worker::swh_loader_git_disk {
  include ::profile::swh::deploy::base_loader_git

  $concurrency = hiera('swh::deploy::worker::swh_loader_git_disk::concurrency')
  $loglevel = hiera('swh::deploy::worker::swh_loader_git_disk::loglevel')
  $task_broker = hiera('swh::deploy::worker::swh_loader_git_disk::task_broker')

  $config_file = '/etc/softwareheritage/loader/git-loader.yml'
  $config = hiera('swh::deploy::worker::swh_loader_git_disk::config')

  $task_modules = ['swh.loader.git.tasks']
  $task_queues = ['swh_loader_git', 'swh_loader_git_express']

  ::profile::swh::deploy::worker::instance {'swh_loader_git_disk':
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
