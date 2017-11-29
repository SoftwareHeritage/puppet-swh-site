# Deployment for swh-loader-deposit
class profile::swh::deploy::worker::swh_loader_deposit {
  $concurrency = hiera('swh::deploy::worker::swh_loader_deposit::concurrency')
  $loglevel = hiera('swh::deploy::worker::swh_loader_deposit::loglevel')
  $task_broker = hiera('swh::deploy::worker::swh_loader_deposit::task_broker')

  $config_dir = hiera('swh::deploy::worker::swh_loader_deposit::swh_conf_dir')
  $config_file = hiera('swh::deploy::worker::swh_loader_deposit::swh_conf_file')
  $config = hiera('swh::deploy::worker::swh_loader_deposit::config')

  $task_modules = ['swh.deposit.injection.tasks']
  $task_queues = ['swh_loader_deposit', 'swh_checker_deposit']

  $packages = ['python3-swh.deposit.injection']

  package {$packages:
    ensure => 'present',
  }

  ::profile::swh::deploy::worker::instance {'swh_loader_deposit':
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

  $swh_client_conf_file = hiera('swh::deploy::deposit::client::swh_conf_file')
  $swh_client_config = hiera('swh::deploy::deposit::client::settings_private_data')
  file {$swh_client_conf_file:
    owner   => 'swhworker',
    group   => 'swhworker',
    mode    => '0644',
    content => inline_template("<%= @swh_client_config.to_yaml %>\n"),
  }
}
