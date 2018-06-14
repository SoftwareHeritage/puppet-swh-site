# Deployment of the swh.objstorage.checker.ArchiveNotifierContentChecker

class profile::swh::deploy::objstorage_archive_notifier_checker {
  $conf_directory = lookup('swh::deploy::objstorage_archive_notifier_checker::conf_directory')
  $conf_file = lookup('swh::deploy::objstorage_archive_notifier_checker::conf_file')
  $user = lookup('swh::deploy::objstorage_archive_notifier_checker::user')
  $group = lookup('swh::deploy::objstorage_archive_notifier_checker::group')

  # configuration file
  $archive_notifier_config = lookup('swh::deploy::objstorage_archive_notifier_checker::config')

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
    content => inline_template("<%= @archive_notifier_config.to_yaml %>\n"),
  }

  ::systemd::unit_file {'objstorage_archive_notifier_checker.service':
    ensure  => present,
    content => template('profile/swh/deploy/storage/objstorage_archive_notifier_checker.service.erb'),
    require => [
      File[$conf_file],
      Package[$swh_packages],
    ]
  }
}
