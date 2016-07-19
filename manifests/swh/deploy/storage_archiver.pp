# Deployment of swh.storage.archiver.director instance
# Only asynchronous version possible.
# Cron not installed since we need to run one synchronous batch first
# to catch up

class profile::swh::deploy::storage_archiver {
  $conf_directory = hiera('swh::deploy::storage_archiver::conf_directory')
  $conf_file = hiera('swh::deploy::storage_archiver::conf_file')
  $user = hiera('swh::deploy::storage_archiver::user')
  $group = hiera('swh::deploy::storage_archiver::group')

  $objstorage_path = hiera('swh::deploy::storage_archiver::objstorage_path')
  $batch_max_size = hiera('swh::deploy::storage_archiver::batch_max_size')
  $archival_max_age = hiera('swh::deploy::storage_archiver::archival_max_age')
  $retention_policy = hiera('swh::deploy::storage_archiver::retention_policy')
  # archiver db info
  $db_host = hiera('swh::deploy::storage_archiver::db::host')
  $db_user = hiera('swh::deploy::storage_archiver::db::user')
  $db_dbname = hiera('swh::deploy::storage_archiver::db::dbname')
  $db_password = hiera('swh::deploy::storage_archiver::db::password')
  # storage db info
  $db_host_storage = hiera('swh::deploy::storage_archiver::db::host_storage')
  $db_user_storage = hiera('swh::deploy::storage_archiver::db::user_storage')
  $db_dbname_storage = hiera('swh::deploy::storage_archiver::db::dbname_storage')
  $db_password_storage = hiera('swh::deploy::storage_archiver::db::password_storage')

  $log_file = hiera('swh::deploy::storage_archiver::log::file')

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
    content => template('profile/swh/deploy/storage/archiver.ini.erb'),
    require => [
      File[$conf_directory]
    ]
  }

  # cron {'swh-storage-archiver':
  #   ensure   => present,
  #   user     => $user,
  #   command  => "/usr/bin/python3 -m swh.storage.archiver.director --config-path ${conf_file} --async 2>&1 > ${log_file}",
  #   hour     => fqdn_rand(24, 'stats_export_hour'),
  #   minute   => fqdn_rand(60, 'stats_export_minute'),
  #   month    => '*',
  #   monthday => '*',
  #   weekday  => '*',
  #   require  => [
  #     File[$conf_file]
  #   ]
  # }

}
