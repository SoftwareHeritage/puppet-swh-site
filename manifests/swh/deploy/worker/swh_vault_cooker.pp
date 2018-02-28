# Deployment of a vault cooker

class profile::swh::deploy::worker::swh_vault_cooker {
  include ::profile::swh::deploy::base_vault

  $concurrency = lookup('swh::deploy::worker::swh_vault_cooker::concurrency')
  $loglevel = lookup('swh::deploy::worker::swh_vault_cooker::loglevel')
  $task_broker = lookup('swh::deploy::worker::swh_vault_cooker::task_broker')

  $conf_file = lookup('swh::deploy::worker::swh_vault_cooker::conf_file')
  $config = lookup('swh::deploy::worker::swh_vault_cooker::config')

  $task_modules = ['swh.vault.cooking_tasks']
  $task_queues = ['swh_vault_cooking']

  ::profile::swh::deploy::worker::instance {'swh_vault_cooker':
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
