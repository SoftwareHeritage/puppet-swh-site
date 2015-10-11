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

  $uwsgi_listen_address = hiera('swh::deploy::storage::uwsgi::listen')
  $uwsgi_protocol = hiera('swh::deploy::storage::uwsgi::protocol')
  $uwsgi_workers = hiera('swh::deploy::storage::uwsgi::workers')
  $uwsgi_max_requests = hiera('swh::deploy::storage::uwsgi::max_requests')
  $uwsgi_max_requests_delta = hiera('swh::deploy::storage::uwsgi::max_requests_delta')
  $uwsgi_reload_mercy = hiera('swh::deploy::storage::uwsgi::reload_mercy')

  include ::uwsgi

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

  ::uwsgi::site {'swh-storage':
    ensure   => enabled,
    settings => {
      plugin              => 'python3',
      protocol            => $uwsgi_protocol,
      socket              => $uwsgi_listen_address,
      workers             => $uwsgi_workers,
      max_requests        => $uwsgi_max_requests,
      max_requests_delta  => $uwsgi_max_requests_delta,
      worker_reload_mercy => $uwsgi_reload_mercy,
      reload_mercy        => $uwsgi_reload_mercy,
      uid                 => $user,
      gid                 => $user,
      umask               => '022',
      module              => 'swh.storage.api.server',
      callable            => 'run_from_webserver',
    }
  }
}
