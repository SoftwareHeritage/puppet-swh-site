# Deployment of a vault cooker

class profile::swh::deploy::worker::vault_cooker {
  $concurrency = hiera('swh::deploy::worker::vault_cooker::concurrency')
  $loglevel = hiera('swh::deploy::worker::vault_cooker::loglevel')
  $task_broker = hiera('swh::deploy::worker::vault_cooker::task_broker')

  $conf_file = hiera('swh::deploy::worker::vault_cooker::conf_file')
  $config = hiera('swh::deploy::worker::vault_cooker::config')

  $task_modules = ['swh.vault.cooking_tasks']
  $task_queues = ['swh_vault_cooking']

  $packages = ['python3-swh.vault']

  package {$packages:
    ensure => 'present',
  }

  ::profile::swh::deploy::worker::instance {'swh_vault_cooking':
    ensure       => present,
    concurrency  => $concurrency,
    loglevel     => $loglevel,
    task_broker  => $task_broker,
    task_modules => $task_modules,
    task_queues  => $task_queues,
    require      => [
      Package[$packages],
      File[$conf_file],
    ],
  }

  file {$conf_file:
    ensure  => 'present',
    owner   => 'swhworker',
    group   => 'swhworker',
    mode    => '0644',
    content => inline_template("<%= @config.to_yaml %>\n"),
  }
}
