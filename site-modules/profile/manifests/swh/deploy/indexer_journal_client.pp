# Deployment of the swh.indexer.journal_client
class profile::swh::deploy::indexer_journal_client {
  include ::profile::swh::deploy::base_indexer
  include ::profile::swh::deploy::journal

  $config_file = lookup('swh::deploy::indexer_journal_client::config_file')
  $config_directory = lookup('swh::deploy::base_indexer::config_directory')
  $config_path = "${config_directory}/${config_file}"
  $config = lookup('swh::deploy::indexer_journal_client::config')

  $user = lookup('swh::deploy::indexer_journal_client::user')
  $group = lookup('swh::deploy::indexer_journal_client::group')

  $service_name = 'swh-indexer-journal-client'
  $unit_name = "${service_name}.service"

  file {$config_path:
    ensure  => present,
    owner   => 'root',
    group   => 'swhdev',
    mode    => '0644',
    content => inline_template("<%= @config.to_yaml %>\n"),
    notify  => Service[$service_name],
  }

  # Template uses variables
  #  - $user
  #  - $group
  #
  ::systemd::unit_file {$unit_name:
    ensure  => present,
    content => template("profile/swh/deploy/journal/${unit_name}.erb"),
  } ~> service {$service_name:
    ensure => running,
    enable => true,
  }
}
