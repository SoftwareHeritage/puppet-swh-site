# Deployment of the swh.search.journal_client
class profile::swh::deploy::search_journal_client {
  include ::profile::swh::deploy::base_search
  include ::profile::swh::deploy::journal

  $config_path = lookup('swh::deploy::search_journal_client::config_file')
  $config = lookup('swh::deploy::search_journal_client::config')

  $service_name = 'swh-search-journal-client'
  $unit_name = "${service_name}.service"
  $user = lookup('swh::deploy::base_search::user')
  $group = lookup('swh::deploy::base_search::group')

  Package['python3-swh.search'] ~> Service[$service_name]

  file {$config_path:
    ensure  => present,
    owner   => 'root',
    group   => 'swhdev',
    mode    => '0644',
    content => inline_template("<%= @config.to_yaml %>\n"),
    notify  => Service[$service_name],
  }

  ::systemd::unit_file {$unit_name:
    ensure  => present,
    content => template("profile/swh/deploy/journal/${unit_name}.erb"),
  } ~> service {$service_name:
    ensure => running,
    enable => true,
  }
}
