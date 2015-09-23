# Deployment of the swh.storage.api server

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
  $uwsgi_packages = ['uwsgi', 'uwsgi-plugin-python3']
  $uwsgi_port = hiera('swh::deploy::storage::uwsgi::port')

  $apache_port = hiera('swh::deploy::storage::apache::port')

  package {$uwsgi_packages:
    ensure => installed,
  }

  service {'uwsgi':
    ensure  => running,
    enable  => true,
    require => File[$uwsgi_link],
  }

  include ::apache
  include ::apache::mod::proxy

  ::apache::mod {'proxy_fcgi':}

  ::apache::vhost {'swhstorage':
    ip         => '127.0.0.1',
    port       => $apache_port,
    docroot    => '/var/www/html',
    proxy_pass => [
      {
        'path'   => '/',
        'url'    => "fcgi://127.0.0.1:${uwsgi_port}",
      },
    ]
  }

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
    content => template('profile/swh/deploy/storage/storage.ini.erb'),
    notify  => Service['uwsgi'],
  }

  file {$uwsgi_config:
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('profile/swh/deploy/storage/uwsgi.ini.erb'),
    notify  => Service['uwsgi'],
    require => [
      Package[$uwsgi_packages],
      Package[$swh_packages],
      File[$conf_file],
    ],
  }

  file {$uwsgi_link:
    ensure => link,
    target => $uwsgi_config,
  }
}
