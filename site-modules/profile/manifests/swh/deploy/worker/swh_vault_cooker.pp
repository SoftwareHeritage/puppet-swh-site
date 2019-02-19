# Deployment of a vault cooker

class profile::swh::deploy::worker::swh_vault_cooker {
  include ::profile::swh::deploy::base_vault

  $concurrency = lookup('swh::deploy::worker::swh_vault_cooker::concurrency')
  $loglevel = lookup('swh::deploy::worker::swh_vault_cooker::loglevel')

  $conf_file = lookup('swh::deploy::worker::swh_vault_cooker::config_file')
  $config = lookup('swh::deploy::worker::swh_vault_cooker::config')

  ::profile::swh::deploy::worker::instance {'vault_cooker':
    ensure       => present,
    concurrency  => $concurrency,
    loglevel     => $loglevel,
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
