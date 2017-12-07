# Deployment of the swh.indexer.storage.api.server

class profile::swh::deploy::indexer_storage {
  include ::profile::swh::deploy::base_storage

  $conf_file = hiera('swh::deploy::indexer::storage::conf_file')
  $user = hiera('swh::deploy::indexer::storage::user')
  $group = hiera('swh::deploy::indexer::storage::group')

  $swh_packages = ['python3-swh.indexer']

  $backend_listen_host = hiera('swh::deploy::indexer::storage::backend::listen::host')
  $backend_listen_port = hiera('swh::deploy::indexer::storage::backend::listen::port')
  $backend_listen_address = "${backend_listen_host}:${backend_listen_port}"

  $backend_workers = hiera('swh::deploy::indexer::storage::backend::workers')
  $backend_http_keepalive = hiera('swh::deploy::indexer::storage::backend::http_keepalive')
  $backend_http_timeout = hiera('swh::deploy::indexer::storage::backend::http_timeout')
  $backend_reload_mercy = hiera('swh::deploy::indexer::storage::backend::reload_mercy')
  $backend_max_requests = hiera('swh::deploy::indexer::storage::backend::max_requests')
  $backend_max_requests_jitter = hiera('swh::deploy::indexer::storage::backend::max_requests_jitter')

  $idx_storage_config = hiera('swh::deploy::indexer::storage::config')

  include ::gunicorn

  package {$swh_packages:
    ensure  => latest,
    require => Apt::Source['softwareheritage'],
    notify  => Service['gunicorn-swh-indexer-storage'],
  }

  file {$conf_file:
    ensure  => present,
    owner   => 'root',
    group   => $group,
    mode    => '0640',
    content => inline_template("<%= @idx_storage_config.to_yaml %>\n"),
    notify  => Service['gunicorn-swh-indexer-storage'],
  }

  ::gunicorn::instance {'swh-indexer-storage':
    ensure     => enabled,
    user       => $user,
    group      => $group,
    executable => 'swh.indexer.storage.api.server:run_from_webserver',
    settings   => {
      bind                => $backend_listen_address,
      workers             => $backend_workers,
      worker_class        => 'sync',
      timeout             => $backend_http_timeout,
      graceful_timeout    => $backend_reload_mercy,
      keepalive           => $backend_http_keepalive,
      max_requests        => $backend_max_requests,
      max_requests_jitter => $backend_max_requests_jitter,
    }
  }

  $icinga_checks_file = '/etc/icinga2/conf.d/exported-checks.conf'

  @@::icinga2::object::service {"swh-indexer-storage api (localhost on ${::fqdn})":
    service_name     => 'swh-indexer-storage api (localhost)',
    import           => ['generic-service'],
    host_name        => $::fqdn,
    check_command    => 'http',
    command_endpoint => $::fqdn,
    vars             => {
      http_address => '127.0.0.1',
      http_port    => $backend_listen_port,
      http_uri     => '/',
      http_string  => 'SWH Indexer Storage API server',
    },
    target           => $icinga_checks_file,
    tag              => 'icinga2::exported',
  }

  if $backend_listen_host != '127.0.0.1' {
    @@::icinga2::object::service {"swh-indexer-storage api (remote on ${::fqdn})":
      service_name  => 'swh-indexer-storage api (remote)',
      import        => ['generic-service'],
      host_name     => $::fqdn,
      check_command => 'http',
      vars          => {
        http_port   => $backend_listen_port,
        http_uri    => '/',
        http_string => 'SWH Indexer Storage API server',
      },
      target        => $icinga_checks_file,
      tag           => 'icinga2::exported',
    }
  }
}
