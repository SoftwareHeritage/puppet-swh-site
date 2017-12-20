# Deployment for swh-loader-mercurial (disk)
class profile::swh::deploy::worker::swh_loader_mercurial {
  include ::profile::swh::deploy::base_loader_git

  $concurrency = hiera('swh::deploy::worker::swh_loader_mercurial::concurrency')
  $loglevel = hiera('swh::deploy::worker::swh_loader_mercurial::loglevel')
  $task_broker = hiera('swh::deploy::worker::swh_loader_mercurial::task_broker')

  $config_file = '/etc/softwareheritage/loader/hg.yml'
  $config = hiera('swh::deploy::worker::swh_loader_mercurial::config')

  $task_modules = ['swh.loader.mercurial.tasks']
  $task_queues = ['swh_loader_mercurial',
                  'swh_loader_mercurial_slow',
                  'swh_loader_mercurial_slow_archive']

  $service_name = 'swh_loader_mercurial'


  $packages = ['python3-swh.loader.mercurial']

  package {$packages:
    ensure => 'latest',
    notify => Service["swh-worker@$service_name"]
  }

  ::profile::swh::deploy::worker::instance {$service_name:
    ensure       => running,
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
    group   => 'swhworker',
    mode    => '0644',
    content => inline_template("<%= @config.to_yaml %>\n"),
  }
}
