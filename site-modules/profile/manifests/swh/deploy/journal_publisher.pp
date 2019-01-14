# Deployment of the swh.journal.publisher

class profile::swh::deploy::journal_publisher {
  include ::profile::swh::deploy::journal

  $conf_file = lookup('swh::deploy::journal_publisher::conf_file')
  $user = lookup('swh::deploy::journal_publisher::user')
  $group = lookup('swh::deploy::journal_publisher::group')

  $publisher_config = lookup('swh::deploy::journal_publisher::config')

  $service_name = 'swh-journal-publisher'
  $unit_name = "${service_name}.service"

  file {$conf_file:
    ensure  => present,
    owner   => 'root',
    group   => $group,
    mode    => '0640',
    content => inline_template("<%= @publisher_config.to_yaml %>\n"),
    notify  => Service[$service_name],
  }

  # Template uses variables
  #  - $user
  #  - $group
  #
  ::systemd::unit_file {$unit_name:
    ensure  => present,
    content => template('profile/swh/deploy/journal/swh-journal-publisher.service.erb'),
  } ~> service {$service_name:
    ensure => running,
    enable => true,
  }
}
