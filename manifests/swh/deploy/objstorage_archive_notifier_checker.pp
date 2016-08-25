# Deployment of the swh.objstorage.checker.ArchiveNotifierContentChecker

class profile::swh::deploy::objstorage_archive_notifier_checker {
  $conf_directory = hiera('swh::deploy::objstorage_archive_notifier_checker::conf_directory')
  $conf_file = hiera('swh::deploy::objstorage_archive_notifier_checker::conf_file')
  $user = hiera('swh::deploy::objstorage_archive_notifier_checker::user')
  $group = hiera('swh::deploy::objstorage_archive_notifier_checker::group')

  # configuration file
  $directory = hiera('swh::deploy::objstorage_archive_notifier_checker::directory')
  $slicing = hiera('swh::deploy::objstorage_archive_notifier_checker::slicing')
  $checker_class = hiera('swh::deploy::objstorage_archive_notifier_checker::class')
  $batch_size = hiera('swh::deploy::objstorage_archive_notifier_checker::batch_size')
  $log_tag = hiera('swh::deploy::objstorage_archive_notifier_checker::log_tag')

  $db_host = hiera('swh::deploy::objstorage_archive_notifier_checker::db::host')
  $db_dbname = hiera('swh::deploy::objstorage_archive_notifier_checker::db::dbname')
  $db_user = hiera('swh::deploy::objstorage_archive_notifier_checker::db::user')
  $db_password = hiera('swh::deploy::objstorage_archive_notifier_checker::db::password')

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
    content => template('profile/swh/deploy/storage/objstorage_archive_notifier_checker.yml.erb'),
  }

  include ::systemd

  file {'/etc/systemd/system/objstorage_archive_notifier_checker.service':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('profile/swh/deploy/storage/objstorage_archive_notifier_checker.service.erb'),
    notify  => Exec['systemd-daemon-reload'],
    require => [
      File[$conf_file],
      Package[$swh_packages],
    ]
  }

}
