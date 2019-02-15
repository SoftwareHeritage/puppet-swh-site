# Deployment for swh-lister-github
class profile::swh::deploy::worker::swh_lister_github {
  $concurrency = lookup('swh::deploy::worker::swh_lister_github::concurrency')
  $loglevel = lookup('swh::deploy::worker::swh_lister_github::loglevel')
  $task_broker = lookup('swh::deploy::worker::swh_lister_github::task_broker')

  $config_file = lookup('swh::deploy::worker::swh_lister_github::config_file')
  $config = lookup('swh::deploy::worker::swh_lister_github::config', Hash, 'deep')

  $task_modules = ['swh.lister.github.tasks']
  $task_queues = ['swh_lister_github_discover', 'swh_lister_github_refresh']

  include ::profile::swh::deploy::base_lister

  ::profile::swh::deploy::worker::instance {'lister_github':
    ensure       => present,
    concurrency  => $concurrency,
    loglevel     => $loglevel,
    task_broker  => $task_broker,
    task_modules => $task_modules,
    task_queues  => $task_queues,
    require      => [
      Package['python3-swh.lister'],
      File[$config_file],
    ],
  }

  # Contains passwords
  file {$config_file:
    ensure  => 'present',
    owner   => 'swhworker',
    group   => 'swhdev',
    mode    => '0640',
    content => inline_template("<%= @config.to_yaml %>\n"),
  }
}
