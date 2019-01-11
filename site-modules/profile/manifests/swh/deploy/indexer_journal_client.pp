# Deployment of the swh.indexer.journal_client

class profile::swh::deploy::indexer_journal_client {
  include ::profile::swh::deploy::journal

  $conf_file = lookup('swh::deploy::indexer_journal_client::conf_file')
  $user = lookup('swh::deploy::indexer_journal_client::user')
  $group = lookup('swh::deploy::indexer_journal_client::group')

  $config = lookup('swh::deploy::indexer_journal_client::config')
  $service_name = 'swh-indexer-journal-client'
  $unit_name = "${service_name}.service"

  $packages = ['python3-swh.indexer']
  package {$packages:
    ensure => 'present',
    notify => Service[$service_name],
  }

  file {$conf_file:
    ensure  => present,
    owner   => root,
    group   => $group,
    mode    => '0640',
    content => inline_template("<%= @config.to_yaml %>\n"),
    notify  => Service[$service_name],
  }

  # Template uses variables
  #  - $user
  #  - $group
  #
  ::systemd::unit {$unit_name:
    ensure  => present,
    content => template("profile/swh/deploy/journal/${unit_name}.erb"),
  } ~> service {$service_name:
    ensure => running,
    enable => false,
  }
}
