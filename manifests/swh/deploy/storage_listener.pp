# Deployment of the swh.storage.listener

class profile::swh::deploy::storage_listener {
  $conf_directory = lookup('swh::deploy::storage_listener::conf_directory')
  $conf_file = lookup('swh::deploy::storage_listener::conf_file')
  $user = lookup('swh::deploy::storage_listener::user')
  $group = lookup('swh::deploy::storage_listener::group')
  $database = lookup('swh::deploy::storage_listener::database')
  $topic_prefix = lookup('swh::deploy::storage_listener::topic_prefix')
  $kafka_brokers = lookup('swh::deploy::storage_listener::kafka_brokers', Array, 'unique')
  $poll_timeout = lookup('swh::deploy::storage_listener::poll_timeout')

  include ::systemd

  $service_name = 'swh-storage-listener'
  $service_file = "/etc/systemd/system/${service_name}.service"

  package {'python3-swh.storage.listener':
    ensure => latest,
    notify => Service[$service_name],
  }

  file {$conf_directory:
    ensure => directory,
    owner  => 'root',
    group  => $group,
    mode   => '0750',
  }

  # Template uses variables
  #  - $database
  #  - $kafka_brokers
  #  - $topic_prefix
  #  - $poll_timeout
  #
  file {$conf_file:
    ensure  => present,
    owner   => 'root',
    group   => $group,
    mode    => '0640',
    require => File[$conf_directory],
    content => template('profile/swh/deploy/storage_listener/listener.ini.erb'),
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
    content => template('profile/swh/deploy/storage_listener/swh-storage-listener.service.erb'),
    require => Package['python3-swh.storage.listener'],
    notify  => [
      Exec['systemd-daemon-reload'],
      Service[$service_name],
    ],
  }

  service {$service_name:
    ensure  => running,
    enable  => true,
    require => File[$service_file],
  }
}
