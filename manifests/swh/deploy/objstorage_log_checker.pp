# Deployment of the swh.objstorage.checker.LogContentChecker

class profile::swh::deploy::objstorage_log_checker {
  $conf_directory = lookup('swh::deploy::objstorage_log_checker::conf_directory')
  $conf_file = lookup('swh::deploy::objstorage_log_checker::conf_file')
  $user = lookup('swh::deploy::objstorage_log_checker::user')
  $group = lookup('swh::deploy::objstorage_log_checker::group')

  # configuration file
  $log_checker_config = lookup('swh::deploy::objstorage_log_checker::config')

  $swh_packages = ['python3-swh.objstorage.checker']

  package {$swh_packages:
    ensure  => latest,
    require => Apt::Source['softwareheritage'],
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
    content => inline_template("<%= @log_checker_config.to_yaml %>\n"),
  }

  include ::systemd

  file {'/etc/systemd/system/objstorage_log_checker.service':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('profile/swh/deploy/storage/objstorage_log_checker.service.erb'),
    notify  => Exec['systemd-daemon-reload'],
    require => [
      File[$conf_file],
      Package[$swh_packages],
    ]
  }

}
