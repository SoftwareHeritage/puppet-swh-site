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
  $uwsgi_listen_address = hiera('swh::deploy::storage::uwsgi::listen')
  $uwsgi_protocol = hiera('swh::deploy::storage::uwsgi::protocol')
  $uwsgi_workers = hiera('swh::deploy::storage::uwsgi::workers')
  $uwsgi_max_requests = hiera('swh::deploy::storage::uwsgi::max_requests')
  $uwsgi_max_requests_delta = hiera('swh::deploy::storage::uwsgi::max_requests_delta')
  $uwsgi_reload_mercy = hiera('swh::deploy::storage::uwsgi::reload_mercy')

  $systemd_service_dir = '/etc/systemd/system/uwsgi.service.d'
  $systemd_service_file = "${systemd_service_dir}/setrlimit.conf"

  include profile::swh::systemd

  package {$uwsgi_packages:
    ensure => installed,
  }

  service {'uwsgi':
    ensure  => running,
    enable  => true,
    require => [
      Package[$uwsgi_packages],
      File[$uwsgi_link],
      Exec['systemd-daemon-reload'],
    ]
  }

  package {$swh_packages:
    ensure  => latest,
    require => Apt::Source['softwareheritage'],
    notify  => Service['uwsgi'],
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

  file {$systemd_service_dir:
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

  file {$systemd_service_file:
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('profile/swh/deploy/storage/systemd-setrlimit.conf.erb'),
    require => File[$systemd_service_dir],
    notify  => [
      Service['uwsgi'],
      Exec['systemd-daemon-reload'],
    ]
  }
}
