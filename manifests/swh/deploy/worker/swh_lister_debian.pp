# Deployment for swh-lister-debian
class profile::swh::deploy::worker::swh_lister_debian {
  $concurrency = hiera('swh::deploy::worker::swh_lister_debian::concurrency')
  $loglevel = hiera('swh::deploy::worker::swh_lister_debian::loglevel')
  $task_broker = hiera('swh::deploy::worker::swh_lister_debian::task_broker')

  $config_file = '/etc/softwareheritage/lister-debian.yml'
  $config = hiera_hash('swh::deploy::worker::swh_lister_debian::config')

  $task_modules = ['swh.lister.debian.tasks']
  $task_queues = ['swh_lister_debian']

  include ::profile::swh::deploy::base_lister

  ::profile::swh::deploy::worker::instance {'swh_lister_debian':
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
