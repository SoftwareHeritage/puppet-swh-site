class profile::swh::deploy::storage {
  $conf_directory = hiera('swh::deploy::storage::conf_directory')
  $conf_file = hiera('swh::deploy::storage::conf_file')
  $user = hiera('swh::deploy::storage::user')
  $group = hiera('swh::deploy::storage::group')
  $db_host = hiera('swh::deploy::storage::db::host')
  $db_user = hiera('swh::deploy::storage::db::user')
  $db_dbname = hiera('swh::deploy::storage::db::dbname')
  $db_password = hiera('swh::deploy::storage::db::password')
  $directory = hiera('swh::deploy::storage::directory')

  $swh_packages = ['python3-swh.storage']

  $uwsgi_config = '/etc/uwsgi/apps-available/swh-storage.ini'
  $uwsgi_link = '/etc/uwsgi/apps-enabled/swh-storage.ini'
  $uswgi_packages = ['uwsgi', 'uwsgi-plugin-python3']
  $uwsgi_port = hiera('swh::deploy::storage::uwsgi::port')

  package {$uwsgi_packages:
    ensure => installed,
  }

  service {'uwsgi':
    ensure  => running,
    enable  => true,
    require => File[$uwsgi_link],
  }

  include ::apache

  package {$swh_packages:
    ensure  => latest,
    require => Apt::Repo['softwareheritage'],
  }

  file {$conf_directory:
    ensure => directory,
    owner  => 'root',
    group  => $group,
    mode   => '0750',
  }

  file {$conf_file:
    ensure => present,
    owner  => root,
    group  => $group,
    mode   => '0640',
    contents => template('profile/swh/deploy/storage/storage.ini.erb'),
  }

  file {$uwsgi_config:
    ensure   => present,
    owner    => 'root'
    group    => 'root',
    mode     => '0644',
    contents => template('profile/swh/deploy/storage/uwsgi.ini.erb'),
    notify   => Service['uwsgi'],
    require  => [
      Package[$uwsgi_packages],
      Package[$swh_packages],
    ],
  }

  file {$uwsgi_link:
    ensure => link,
    target => $uwsgi_config,
  }
}
