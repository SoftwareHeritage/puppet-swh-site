# Deployment of the swh.objstorage.api server

class profile::swh::deploy::objstorage {
  $conf_directory = hiera('swh::deploy::objstorage::conf_directory')
  $conf_file = hiera('swh::deploy::objstorage::conf_file')
  $user = hiera('swh::deploy::objstorage::user')
  $group = hiera('swh::deploy::objstorage::group')

  $objstorage_config = hiera('swh::deploy::objstorage::config')

  $swh_packages = ['python3-swh.objstorage']

  $backend_listen_address = hiera('swh::deploy::objstorage::backend::listen')
  $backend_workers = hiera('swh::deploy::objstorage::backend::workers')
  $backend_http_keepalive = hiera('swh::deploy::objstorage::backend::http_keepalive')
  $backend_http_timeout = hiera('swh::deploy::objstorage::backend::http_timeout')
  $backend_reload_mercy = hiera('swh::deploy::objstorage::backend::reload_mercy')

  include ::gunicorn

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
    notify  => Service['gunicorn-swh-objstorage'],
  }

  ::gunicorn::instance {'swh-objstorage':
    ensure     => enabled,
    user       => $user,
    group      => $group,
    executable => 'swh.objstorage.api.server:run_from_webserver',
    settings   => {
      bind             => $backend_listen_address,
      workers          => $backend_workers,
      worker_class     => 'sync',
      timeout          => $backend_http_timeout,
      graceful_timeout => $backend_reload_mercy,
      keepalive        => $backend_http_keepalive,
    }
  }

}
