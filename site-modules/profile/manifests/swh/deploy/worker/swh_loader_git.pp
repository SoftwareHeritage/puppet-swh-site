# Deployment for swh-loader-git (remote)
class profile::swh::deploy::worker::swh_loader_git {
  include ::profile::swh::deploy::base_loader_git

  $concurrency = lookup('swh::deploy::worker::swh_loader_git::concurrency')
  $loglevel = lookup('swh::deploy::worker::swh_loader_git::loglevel')
  $task_broker = lookup('swh::deploy::worker::swh_loader_git::task_broker')

  $config_file = lookup('swh::deploy::worker::swh_loader_git::config_file')
  $config_directory = lookup('swh::conf_directory')
  $config_path = "${config_directory}/${config_file}"
  $config = lookup('swh::deploy::worker::swh_loader_git::config')

  $task_modules = ['swh.loader.git.tasks']
  $task_queues = ['swh_loader_git']

  ::profile::swh::deploy::worker::instance {'swh_loader_git':
    ensure       => present,
    concurrency  => $concurrency,
    loglevel     => $loglevel,
    task_broker  => $task_broker,
    task_modules => $task_modules,
    task_queues  => $task_queues,
    require      => [
      Class['profile::swh::deploy::base_loader_git'],
      File[$config_path],
    ],
  }

  file {$config_path:
    ensure  => 'present',
    owner   => 'swhworker',
    group   => 'swhworker',
    mode    => '0644',
    content => inline_template("<%= @config.to_yaml %>\n"),
  }
}
