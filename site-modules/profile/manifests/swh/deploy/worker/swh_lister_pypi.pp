# Deployment for swh-lister-pypi
class profile::swh::deploy::worker::swh_lister_pypi {
  $concurrency = lookup('swh::deploy::worker::swh_lister_pypi::concurrency')
  $loglevel = lookup('swh::deploy::worker::swh_lister_pypi::loglevel')
  $task_broker = lookup('swh::deploy::worker::swh_lister_pypi::task_broker')

  $config_file = '/etc/softwareheritage/lister-pypi.yml'
  $config = lookup('swh::deploy::worker::swh_lister_pypi::config', Hash, 'deep')

  $task_modules = ['swh.lister.pypi.tasks']
  $task_queues = ['swh_lister_pypi_refresh']

  include ::profile::swh::deploy::base_lister

  ::profile::swh::deploy::worker::instance {'swh_lister_pypi':
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
