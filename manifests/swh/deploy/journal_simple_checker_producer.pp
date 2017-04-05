# Deployment of the swh.journal.checker

class profile::swh::deploy::journal_simple_checker_producer {
  include ::profile::swh::deploy::journal

  $conf_file = hiera('swh::deploy::journal_simple_checker_producer::conf_file')
  $user = hiera('swh::deploy::journal_simple_checker_producer::user')
  $group = hiera('swh::deploy::journal_simple_checker_producer::group')

  $checker_config = hiera(
    'swh::deploy::journal_simple_checker_producer::config')

  include ::systemd

  $service_name = 'swh-journal-simple-checker-producer'
  $service_file = "/etc/systemd/system/${service_name}.service"

  file {$conf_directory:
    ensure => directory,
    owner  => 'root',
    group  => $group,
    mode   => '0750',
  }

  file {$conf_file:
    ensure  => present,
    owner   => 'root',
    group   => $group,
    mode    => '0640',
    require => File[$conf_directory],
    content => inline_template('<%= @checker_config.to_yaml %>\n'),
    notify  => Service[$service_name],
  }

  # Template uses variables
  #  - $user
  #  - $group
  #
  file {$service_file:
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('profile/swh/deploy/journal/swh-journal-simple-checker-producer.service.erb'),
    require => Package[$package_name],
    notify  => [
      Exec['systemd-daemon-reload'],
      Service[$service_name],
    ],
  }

  service {$service_name:
    ensure  => running,
    enable  => false,
    require => File[$service_file],
  }
}
