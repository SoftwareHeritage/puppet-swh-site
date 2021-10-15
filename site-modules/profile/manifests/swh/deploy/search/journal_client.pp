# Deployment of the swh.search.journal_client
class profile::swh::deploy::search::journal_client {
  include profile::swh::deploy::journal

  $service_types = lookup('swh::deploy::search::journal_client::service_types')

  $systemd_template_unit_name = 'swh-search-journal-client@.service'
  $config_directory = lookup('swh::deploy::base_search::config_directory')

  $user = lookup('swh::deploy::base_search::user')
  $group = lookup('swh::deploy::base_search::group')

  $sentry_dsn = lookup("swh::deploy::search::sentry_dsn", Optional[String], 'first', undef)
  $sentry_environment = lookup("swh::deploy::search::sentry_environment", Optional[String], 'first', undef)
  $sentry_swh_package = lookup("swh::deploy::search::sentry_swh_package", Optional[String], 'first', undef)

  # Uses:
  # - $config_directory
  # - $user
  # - $group
  # - $sentry_{dsn,environment,swh_package}
  systemd::unit_file {$systemd_template_unit_name:
    ensure  => 'present',
    content => template("profile/swh/deploy/journal/${systemd_template_unit_name}.erb"),
  }

  $service_types.each | $service_type | {
    profile::swh::deploy::search::journal_client_instance {$service_type:
      ensure  => 'running',
      require => Package['python3-swh.search'],
    }
  }
}
