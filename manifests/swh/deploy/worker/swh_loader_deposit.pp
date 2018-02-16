# Deployment for swh-loader-deposit
class profile::swh::deploy::worker::swh_loader_deposit {
  $concurrency = hiera('swh::deploy::worker::swh_loader_deposit::concurrency')
  $loglevel = hiera('swh::deploy::worker::swh_loader_deposit::loglevel')
  $task_broker = hiera('swh::deploy::worker::swh_loader_deposit::task_broker')

  $deposit_config_directory = hiera('swh::deploy::deposit::conf_directory')
  $config_file = hiera('swh::deploy::worker::swh_loader_deposit::swh_conf_file')
  $config = hiera('swh::deploy::worker::swh_loader_deposit::config')

  $task_modules = ['swh.deposit.loader.tasks']
  $task_queues = ['swh_checker_deposit', 'swh_loader_deposit']

  $packages = ['python3-swh.deposit.loader']
  $private_tmp = hiera('swh::deploy::worker::swh_loader_deposit::private_tmp')

  $service_name = 'swh_loader_deposit'

  package {$packages:
    ensure => 'latest',
    notify => Service["swh-worker@$service_name"],
  }

  # This installs the swh-worker@$service_name service
  ::profile::swh::deploy::worker::instance {$service_name:
    ensure       => running,
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

  file {$deposit_config_directory:
    ensure => directory,
    owner  => 'swhworker',
    group  => 'swhdev',
    mode   => '0750',
  }

  file {$config_file:
    ensure  => 'present',
    owner   => 'swhworker',
    group   => 'swhdev',
    mode    => '0640',
    content => inline_template("<%= @config.to_yaml %>\n"),
    require      => [
      File[$deposit_config_directory],
    ],
  }

  $swh_client_conf_file = hiera('swh::deploy::deposit::client::swh_conf_file')
  $swh_client_config = hiera('swh::deploy::deposit::client::settings_private_data')
  file {$swh_client_conf_file:
    owner   => 'swhworker',
    group   => 'swhdev',
    mode    => '0640',
    content => inline_template("<%= @swh_client_config.to_yaml %>\n"),
  }
}
