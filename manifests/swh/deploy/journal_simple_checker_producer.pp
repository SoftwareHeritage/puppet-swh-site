# Deployment of the swh.journal.checker

class profile::swh::deploy::journal_simple_checker_producer {
  include ::profile::swh::deploy::journal

  $conf_file = lookup('swh::deploy::journal_simple_checker_producer::conf_file')
  $user = lookup('swh::deploy::journal_simple_checker_producer::user')
  $group = lookup('swh::deploy::journal_simple_checker_producer::group')

  $checker_config = lookup(
    'swh::deploy::journal_simple_checker_producer::config')

  $service_name = 'swh-journal-simple-checker-producer'
  $unit_name = "${service_name}.service"

  file {$conf_file:
    ensure  => present,
    owner   => 'root',
    group   => $group,
    mode    => '0640',
    content => inline_template("<%= @checker_config.to_yaml %>\n"),
    notify  => Service[$service_name],
  }

  # Template uses variables
  #  - $user
  #  - $group
  #
  ::systemd::unit {$unit_name:
    ensure  => present,
    content => template('profile/swh/deploy/journal/swh-journal-simple-checker-producer.service.erb'),
  } ~> service {$service_name:
    ensure => running,
    enable => false,
  }
}
