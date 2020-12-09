# Deployment of the swh.search.journal_client
class profile::swh::deploy::search::journal_client {
  include profile::swh::deploy::journal

  $service_types = lookup('swh::deploy::search::journal_client::service_types')

  $systemd_template_unit_name = 'swh-search-journal-client@.service'
  $config_directory = lookup("swh::deploy::base_search::config_directory")

  $user = lookup('swh::deploy::base_search::user')
  $group = lookup('swh::deploy::base_search::group')

  # Uses:
  # - $config_directory
  # - $user
  # - $group
  systemd::unit_file {$systemd_template_unit_name:
    ensure => 'present',
    content => template("profile/swh/deploy/journal/${systemd_template_unit_name}.erb"),
  }

  $service_types.each | $service_type | {
    profile::swh::deploy::search::journal_client_instance {$service_type:
      ensure  => 'running',
      require => Package['python3-swh.search'],
    }
  }
}
