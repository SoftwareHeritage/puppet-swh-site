# Deployment of the swh.deposit server

class profile::swh::deploy::deposit {
  $conf_directory = hiera('swh::deploy::deposit::conf_directory')

  $swh_conf_file = hiera('swh::deploy::deposit::swh_conf_file')
  $user = hiera('swh::deploy::deposit::user')
  $group = hiera('swh::deploy::deposit::group')
  $swh_conf_raw = hiera('swh::deploy::deposit::config')

  $swh_packages = ['python3-swh.deposit']

  # private data file to read from swh.deposit.settings.production
  $settings_private_data_file = hiera('swh::deploy::deposit::settings_private_data_file')
  $settings_private_data = hiera('swh::deploy::deposit::settings_private_data')

  $backend_listen_host = hiera('swh::deploy::deposit::backend::listen::host')
  $backend_listen_port = hiera('swh::deploy::deposit::backend::listen::port')
  $backend_listen_address = "${backend_listen_host}:${backend_listen_port}"

  $backend_workers = hiera('swh::deploy::deposit::backend::workers')
  $backend_http_keepalive = hiera('swh::deploy::deposit::backend::http_keepalive')
  $backend_http_timeout = hiera('swh::deploy::deposit::backend::http_timeout')
  $backend_reload_mercy = hiera('swh::deploy::deposit::backend::reload_mercy')

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

  # swh's configuration part (upload size, etc...)
  file {$swh_conf_file:
    ensure  => present,
    owner   => 'root',
    group   => $group,
    mode    => '0640',
    content => inline_template("<%= @swh_conf_raw.to_yaml %>\n"),
    notify  => Service['gunicorn-swh-deposit'],
  }

  # swh's private configuration part (db, secret key)
  file {$settings_private_data_file:
    ensure => present,
    owner => 'root',
    group => $group,
    mode  => '0640',
    content => inline_template("<%= @settings_private_data.to_yaml %>\n"),
    notify  => Service['gunicorn-swh-deposit'],
  }

  ::gunicorn::instance {'swh-deposit':
    ensure     => enabled,
    user       => $user,
    group      => $group,
    executable => 'swh.deposit.wsgi',
    settings   => {
      bind             => $backend_listen_address,
      workers          => $backend_workers,
      worker_class     => 'sync',
      timeout          => $backend_http_timeout,
      graceful_timeout => $backend_reload_mercy,
      keepalive        => $backend_http_keepalive,
    }
  }

  $icinga_checks_file = '/etc/icinga2/conf.d/exported-checks.conf'

  @@::icinga2::object::service {"swh-deposit api (localhost on ${::fqdn})":
    service_name     => 'swh-deposit api (localhost)',
    import           => ['generic-service'],
    host_name        => $::fqdn,
    check_command    => 'http',
    command_endpoint => $::fqdn,
    vars             => {
      http_address => '127.0.0.1',
      http_port    => $backend_listen_port,
      http_uri     => '/deposit/',
      http_string  => 'SWH Deposit API',
    },
    target           => $icinga_checks_file,
    tag              => 'icinga2::exported',
  }

  if $backend_listen_host != '127.0.0.1' {
    @@::icinga2::object::service {"swh-deposit api (remote on ${::fqdn})":
      service_name  => 'swh-deposit api (remote)',
      import        => ['generic-service'],
      host_name     => $::fqdn,
      check_command => 'http',
      vars          => {
        http_port   => $backend_listen_port,
        http_uri    => '/deposit/',
        http_string => 'SWH Deposit API',
      },
      target        => $icinga_checks_file,
      tag           => 'icinga2::exported',
    }
  }
}
