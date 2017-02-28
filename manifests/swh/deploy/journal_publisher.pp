# Deployment of the swh.storage.listener

class profile::swh::deploy::journal_publisher {
  $conf_directory = hiera('swh::deploy::journal_publisher::conf_directory')
  $conf_file = hiera('swh::deploy::journal_publisher::conf_file')
  $user = hiera('swh::deploy::journal_publisher::user')
  $group = hiera('swh::deploy::journal_publisher::group')

  $publisher_config = hiera('swh::deploy::journal_publisher::config')

  include ::systemd

  $service_name = 'swh-journal-publisher'
  $service_file = "/etc/systemd/system/${service_name}.service"

  package_name = 'python3-swh.journal'

  package {$package_name:
    ensure => latest,
    notify => Service[$service_name],
  }

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
    content => inline_template('<%= @publisher_config.to_yaml %>'),
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
    content => template('profile/swh/deploy/journal_publisher/swh-journal-publisher.service.erb'),
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
