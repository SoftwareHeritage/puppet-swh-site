# Deployment of the swh.objstorage.api server

class profile::swh::deploy::objstorage {
  $conf_directory = hiera('swh::deploy::objstorage::conf_directory')
  $conf_file = hiera('swh::deploy::objstorage::conf_file')
  $user = hiera('swh::deploy::objstorage::user')
  $group = hiera('swh::deploy::objstorage::group')

  $objstorage_config = hiera('swh::deploy::objstorage::config')

  $swh_packages = ['python3-swh.objstorage']

  $uwsgi_listen_address = hiera('swh::deploy::objstorage::uwsgi::listen')
  $uwsgi_workers = hiera('swh::deploy::objstorage::uwsgi::workers')
  $uwsgi_http_workers = hiera('swh::deploy::objstorage::uwsgi::http_workers')
  $uwsgi_http_keepalive = hiera('swh::deploy::objstorage::uwsgi::http_keepalive')
  $uwsgi_http_timeout = hiera('swh::deploy::objstorage::uwsgi::http_timeout')
  $uwsgi_max_requests = hiera('swh::deploy::objstorage::uwsgi::max_requests')
  $uwsgi_max_requests_delta = hiera('swh::deploy::objstorage::uwsgi::max_requests_delta')
  $uwsgi_reload_mercy = hiera('swh::deploy::objstorage::uwsgi::reload_mercy')

  include ::uwsgi

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
    content => inline_template("<%= @objstorage_config.to_yaml %>\n"),
  }

  ::uwsgi::site {'swh-objstorage':
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
      module              => 'swh.objstorage.api.server',
      callable            => 'run_from_webserver',
    }
  }

  ::uwsgi::site {'swh-objstorage-http':
    ensure => enabled,
    settings => {
      workers        => 0,
      http           => $uwsgi_listen_address,
      http_workers   => $uwsgi_http_workers,
      http_keepalive => $uwsgi_http_keepalive,
      http_timeout   => $uwsgi_http_timeout,
      http_to        => '/var/run/uwsgi/app/swh-objstorage/socket',
      uid            => $user,
      gid            => $user,
    }
  }
}
