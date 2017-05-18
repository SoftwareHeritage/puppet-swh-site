# Deployment of the swh.storage.api server

class profile::swh::deploy::storage {
  $conf_directory = hiera('swh::deploy::storage::conf_directory')
  $conf_file = hiera('swh::deploy::storage::conf_file')
  $user = hiera('swh::deploy::storage::user')
  $group = hiera('swh::deploy::storage::group')

  $swh_packages = ['python3-swh.storage']

  $backend_listen_address = hiera('swh::deploy::storage::backend::listen')
  $backend_workers = hiera('swh::deploy::storage::backend::workers')
  $backend_http_keepalive = hiera('swh::deploy::storage::backend::http_keepalive')
  $backend_http_timeout = hiera('swh::deploy::storage::backend::http_timeout')
  $backend_reload_mercy = hiera('swh::deploy::storage::backend::reload_mercy')

  $storage_config = hiera('swh::deploy::storage::config')

  include ::gunicorn

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
    notify  => Service['gunicorn-swh-storage'],
  }

  ::gunicorn::instance {'swh-storage':
    ensure     => enabled,
    user       => $user,
    group      => $group,
    executable => 'swh.storage.api.server:run_from_webserver',
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
