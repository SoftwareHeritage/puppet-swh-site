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

  $sentry_dsn = lookup("swh::deploy::indexer::sentry_dsn", Optional[String], 'first', undef)
  $sentry_environment = lookup("swh::deploy::indexer::sentry_environment", Optional[String], 'first', undef)
  $sentry_swh_package = lookup("swh::deploy::indexer::sentry_swh_package", Optional[String], 'first', undef)

  file {$config_path:
    ensure  => present,
    owner   => 'root',
    group   => $group,
    mode    => '0640',
    content => inline_template("<%= @config.to_yaml %>\n"),
    notify  => Service[$service_name],
  }

  # Template uses variables
  #  - $user
  #  - $group
  #  - $sentry_dsn
  #  - $sentry_environment
  #  - $sentry_swh_package
  ::systemd::unit_file {$unit_name:
    ensure  => present,
    content => template("profile/swh/deploy/journal/${unit_name}.erb"),
  } ~> service {$service_name:
    ensure => running,
    enable => true,
  }
}
