# Deployment for swh-loader-svn
class profile::swh::deploy::worker::swh_loader_svn {
  $concurrency = lookup('swh::deploy::worker::swh_loader_svn::concurrency')
  $loglevel = lookup('swh::deploy::worker::swh_loader_svn::loglevel')
  $task_broker = lookup('swh::deploy::worker::swh_loader_svn::task_broker')

  $config_file = '/etc/softwareheritage/loader/svn.yml'
  $config = lookup('swh::deploy::worker::swh_loader_svn::config')

  $task_modules = ['swh.loader.svn.tasks']
  $task_queues = ['swh_loader_svn', 'swh_loader_svn_mount_and_load']

  $packages = ['python3-swh.loader.svn']
  $limit_no_file = lookup('swh::deploy::worker::swh_loader_svn::limit_no_file')
  $private_tmp = lookup('swh::deploy::worker::swh_loader_svn::private_tmp')

  package {$packages:
    ensure => 'latest',
  }

  ::profile::swh::deploy::worker::instance {'swh_loader_svn':
    ensure        => present,
    concurrency   => $concurrency,
    loglevel      => $loglevel,
    task_broker   => $task_broker,
    task_modules  => $task_modules,
    task_queues   => $task_queues,
    limit_no_file => $limit_no_file,
    private_tmp   => $private_tmp,
    require       => [
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
