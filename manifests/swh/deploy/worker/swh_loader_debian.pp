# Deployment for swh-loader-debian
class profile::swh::deploy::worker::swh_loader_debian {
  $concurrency = lookup('swh::deploy::worker::swh_loader_debian::concurrency')
  $loglevel = lookup('swh::deploy::worker::swh_loader_debian::loglevel')
  $task_broker = lookup('swh::deploy::worker::swh_loader_debian::task_broker')

  $config_file = '/etc/softwareheritage/loader/debian.yml'
  $config = lookup('swh::deploy::worker::swh_loader_debian::config')

  $task_modules = ['swh.loader.debian.tasks']
  $task_queues = ['swh_loader_debian']

  $packages = ['python3-swh.loader.debian']

  package {$packages:
    ensure => 'present',
  }

  ::profile::swh::deploy::worker::instance {'swh_loader_debian':
    ensure       => present,
    concurrency  => $concurrency,
    loglevel     => $loglevel,
    task_broker  => $task_broker,
    task_modules => $task_modules,
    task_queues  => $task_queues,
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
