# Deployment for swh-loader-pypi
class profile::swh::deploy::worker::swh_loader_pypi {
  $concurrency = lookup('swh::deploy::worker::swh_loader_pypi::concurrency')
  $loglevel = lookup('swh::deploy::worker::swh_loader_pypi::loglevel')
  $task_broker = lookup('swh::deploy::worker::swh_loader_pypi::task_broker')

  $config_file = lookup('swh::deploy::worker::swh_loader_pypi::config_file')
  $config = lookup('swh::deploy::worker::swh_loader_pypi::config')

  $task_modules = ['swh.loader.pypi.tasks']
  $task_queues = ['swh_loader_pypi']
  $private_tmp = lookup('swh::deploy::worker::swh_loader_pypi::private_tmp')

  $packages = ['python3-swh.loader.pypi']

  package {$packages:
    ensure => 'latest',
  }

  ::profile::swh::deploy::worker::instance {'loader_pypi':
    ensure       => present,
    concurrency  => $concurrency,
    loglevel     => $loglevel,
    task_broker  => $task_broker,
    task_modules => $task_modules,
    task_queues  => $task_queues,
    private_tmp  => $private_tmp,
    require      => [
      Package[$packages],
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
