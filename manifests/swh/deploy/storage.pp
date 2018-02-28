# Deployment of the swh.storage.api server

class profile::swh::deploy::storage {
  include ::profile::swh::deploy::base_storage

  $conf_file = lookup('swh::deploy::storage::conf_file')
  $user = lookup('swh::deploy::storage::user')
  $group = lookup('swh::deploy::storage::group')

  $swh_packages = ['python3-swh.storage']

  $backend_listen_host = lookup('swh::deploy::storage::backend::listen::host')
  $backend_listen_port = lookup('swh::deploy::storage::backend::listen::port')
  $backend_listen_address = "${backend_listen_host}:${backend_listen_port}"

  $backend_workers = lookup('swh::deploy::storage::backend::workers')
  $backend_http_keepalive = lookup('swh::deploy::storage::backend::http_keepalive')
  $backend_http_timeout = lookup('swh::deploy::storage::backend::http_timeout')
  $backend_reload_mercy = lookup('swh::deploy::storage::backend::reload_mercy')
  $backend_max_requests = lookup('swh::deploy::storage::backend::max_requests')
  $backend_max_requests_jitter = lookup('swh::deploy::storage::backend::max_requests_jitter')

  $storage_config = lookup('swh::deploy::storage::config')

  include ::gunicorn

  package {$swh_packages:
    ensure  => latest,
    require => Apt::Source['softwareheritage'],
    notify  => Service['gunicorn-swh-storage'],
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

  @@::icinga2::object::service {"swh-storage api (localhost on ${::fqdn})":
    service_name     => 'swh-storage api (localhost)',
    import           => ['generic-service'],
    host_name        => $::fqdn,
    check_command    => 'http',
    command_endpoint => $::fqdn,
    vars             => {
      http_address => '127.0.0.1',
      http_port    => $backend_listen_port,
      http_uri     => '/',
      http_string  => 'SWH Storage API server',
    },
    target           => $icinga_checks_file,
    tag              => 'icinga2::exported',
  }

  if $backend_listen_host != '127.0.0.1' {
    @@::icinga2::object::service {"swh-storage api (remote on ${::fqdn})":
      service_name  => 'swh-storage api (remote)',
      import        => ['generic-service'],
      host_name     => $::fqdn,
      check_command => 'http',
      vars          => {
        http_port   => $backend_listen_port,
        http_uri    => '/',
        http_string => 'SWH Storage API server',
      },
      target        => $icinga_checks_file,
      tag           => 'icinga2::exported',
    }
  }
}
