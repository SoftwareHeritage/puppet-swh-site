# Deployment of the swh.counters.journal_client
class profile::swh::deploy::counters::journal_client {
  include ::profile::swh::deploy::base_counters
  include ::profile::swh::deploy::journal

  $config_file = lookup('swh::deploy::counters::journal_client::config_file')
  $config = lookup('swh::deploy::counters::journal_client::config')

  $user = lookup('swh::deploy::base_counters::user')
  $group = lookup('swh::deploy::base_counters::group')

  $service_name = 'swh-counters-journal-client'
  $unit_name = "${service_name}.service"
  $sentry_dsn = lookup("swh::deploy::counters::sentry_dsn", Optional[String], 'first', undef)
  $sentry_environment = lookup("swh::deploy::counters::sentry_environment", Optional[String], 'first', undef)
  $sentry_swh_package = lookup("swh::deploy::counters::sentry_swh_package", Optional[String], 'first', undef)

  file {$config_file:
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
