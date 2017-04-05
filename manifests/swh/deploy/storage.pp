# Deployment of the swh.storage.api server

class profile::swh::deploy::storage {
  $conf_directory = hiera('swh::deploy::storage::conf_directory')
  $conf_file = hiera('swh::deploy::storage::conf_file')
  $user = hiera('swh::deploy::storage::user')
  $group = hiera('swh::deploy::storage::group')

  $swh_packages = ['python3-swh.storage']

  $uwsgi_listen_address = hiera('swh::deploy::storage::uwsgi::listen')
  $uwsgi_workers = hiera('swh::deploy::storage::uwsgi::workers')
  $uwsgi_http_workers = hiera('swh::deploy::storage::uwsgi::http_workers')
  $uwsgi_http_keepalive = hiera('swh::deploy::storage::uwsgi::http_keepalive')
  $uwsgi_http_timeout = hiera('swh::deploy::storage::uwsgi::http_timeout')
  $uwsgi_max_requests = hiera('swh::deploy::storage::uwsgi::max_requests')
  $uwsgi_max_requests_delta = hiera('swh::deploy::storage::uwsgi::max_requests_delta')
  $uwsgi_reload_mercy = hiera('swh::deploy::storage::uwsgi::reload_mercy')

  $storage_config = hiera('swh::deploy::storage::config')

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
    mode   => '0755',
  }

  file {$conf_file:
    ensure  => present,
    owner   => 'root',
    group   => $group,
    mode    => '0640',
    content => inline_template("<%= @storage_config.to_yaml %>\n"),
    notify  => Service['uwsgi'],
  }

  ::uwsgi::site {'swh-storage':
    ensure   => enabled,
    settings => {
      plugin              => 'python3',
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

  ::uwsgi::site {'swh-storage-http':
    ensure => enabled,
    settings => {
      workers        => 0,
      http           => $uwsgi_listen_address,
      http_workers   => $uwsgi_http_workers,
      http_keepalive => $uwsgi_http_keepalive,
      http_timeout   => $uwsgi_http_timeout,
      http_to        => '/var/run/uwsgi/app/swh-storage/socket',
      uid            => $user,
      gid            => $user,
    }
  }
}
