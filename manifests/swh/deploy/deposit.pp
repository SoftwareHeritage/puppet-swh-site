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

  $vhost_name = hiera('swh::deploy::deposit::vhost::name')
  $vhost_aliases = hiera('swh::deploy::deposit::vhost::aliases')
  $vhost_docroot = hiera('swh::deploy::deposit::vhost::docroot')
  $vhost_basic_auth_file = "${conf_directory}/http_auth"
  # swh::deploy::deposit::vhost::basic_auth_content in private
  $vhost_basic_auth_content = hiera('swh::deploy::deposit::vhost::basic_auth_content')
  $vhost_ssl_protocol = hiera('swh::deploy::deposit::vhost::ssl_protocol')
  $vhost_ssl_honorcipherorder = hiera('swh::deploy::deposit::vhost::ssl_honorcipherorder')
  $vhost_ssl_cipher = hiera('swh::deploy::deposit::vhost::ssl_cipher')
  $locked_endpoints = hiera_array('swh::deploy::deposit::locked_endpoints')

  $media_root_directory = hiera('swh::deploy::deposit::media_root_directory')

  include ::gunicorn

  package {$swh_packages:
    ensure  => latest,
    require => Apt::Source['softwareheritage'],
    notify  => Service['gunicorn-swh-deposit'],
  }

  file {$conf_directory:
    ensure => directory,
    owner  => 'root',
    group  => $group,
    mode   => '0755',
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

  file {$media_root_directory:
    ensure => directory,
    owner  => $user,
    group  => $group,
    mode   => '2750',
  }

  # swh's private configuration part (db, secret key, media_root)
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

  $endpoint_directories = $locked_endpoints.map |$endpoint| {
    { path           => "^${endpoint}",
      provider       => 'locationmatch',
      auth_type      => 'Basic',
      auth_name      => 'Software Heritage Deposit',
      auth_user_file => $vhost_basic_auth_file,
      auth_require   => 'valid-user',
    }
  }

  include ::profile::ssl
  include ::profile::apache::common
  include ::apache::mod::proxy
  include ::apache::mod::headers

  ::apache::vhost {"${vhost_name}_non-ssl":
    servername      => $vhost_name,
    serveraliases   => $vhost_aliases,
    port            => '80',
    docroot         => $vhost_docroot,
    redirect_status => 'permanent',
    redirect_dest   => "https://${vhost_name}/",
  }

  $ssl_cert_name = 'star_softwareheritage_org'
  $ssl_cert = $::profile::ssl::certificate_paths[$ssl_cert_name]
  $ssl_ca   = $::profile::ssl::ca_paths[$ssl_cert_name]
  $ssl_key  = $::profile::ssl::private_key_paths[$ssl_cert_name]

  ::apache::vhost {"${vhost_name}_ssl":
    servername           => $vhost_name,
    serveraliases        => $vhost_aliases,
    port                 => '443',
    ssl                  => true,
    ssl_protocol         => $vhost_ssl_protocol,
    ssl_honorcipherorder => $vhost_ssl_honorcipherorder,
    ssl_cipher           => $vhost_ssl_cipher,
    ssl_cert             => $ssl_cert,
    ssl_ca               => $ssl_ca,
    ssl_key              => $ssl_key,
    docroot              => $vhost_docroot,
    request_headers      => [
      "set X_FORWARDED_PROTO 'https' env=HTTPS",
    ],
    proxy_pass           => [
      { path => '/static',
        url  => '!',
      },
      { path => '/robots.txt',
        url  => '!',
      },
      { path => '/favicon.ico',
        url  => '!',
      },
      { path => '/',
        url  => "http://${backend_listen_address}/",
      },
    ],
    directories          => [
      { path     => '/1',
        provider => 'location',
        allow    => 'from all',
        satisfy  => 'Any',
        headers  => ['add Access-Control-Allow-Origin "*"'],
      },
      { path    => $static_dir,
        options => ['-Indexes'],
      },
    ] + $endpoint_directories,
    aliases              => [
      { alias => '/static',
        path  => $static_dir,
      },
      { alias => '/robots.txt',
        path  => "${static_dir}/robots.txt",
      },
    ],
    require              => [
      File[$vhost_basic_auth_file],
      File[$ssl_cert],
      File[$ssl_ca],
      File[$ssl_key],
    ],
  }

  file {$vhost_basic_auth_file:
    ensure  => present,
    owner   => 'root',
    group   => 'www-data',
    mode    => '0640',
    content => $vhost_basic_auth_content,
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
      http_uri     => '/',
      http_string  => 'The Software Heritage Deposit',
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
        http_uri    => '/',
        http_string => 'The Software Heritage Deposit',
      },
      target        => $icinga_checks_file,
      tag           => 'icinga2::exported',
    }
  }

  @@::icinga2::object::service {"swh-deposit http redirect on ${::fqdn}":
    service_name  => 'swh deposit http redirect',
    import        => ['generic-service'],
    host_name     => $::fqdn,
    check_command => 'http',
    vars          => {
      http_address => $vhost_name,
      http_vhost   => $vhost_name,
      http_uri     => '/',
    },
    target        => $icinga_checks_file,
    tag           => 'icinga2::exported',
  }

  @@::icinga2::object::service {"swh-deposit https on ${::fqdn}":
    service_name  => 'swh deposit',
    import        => ['generic-service'],
    host_name     => $::fqdn,
    check_command => 'http',
    vars          => {
      http_address    => $vhost_name,
      http_vhost      => $vhost_name,
      http_ssl        => true,
      http_sni        => true,
      http_uri        => '/',
      http_onredirect => sticky
    },
    target        => $icinga_checks_file,
    tag           => 'icinga2::exported',
  }

  @@::icinga2::object::service {"swh-deposit https certificate ${::fqdn}":
    service_name  => 'swh deposit https certificate',
    import        => ['generic-service'],
    host_name     => $::fqdn,
    check_command => 'http',
    vars          => {
      http_address     => $vhost_name,
      http_vhost       => $vhost_name,
      http_ssl         => true,
      http_sni         => true,
      http_certificate => 60,
    },
    target        => $icinga_checks_file,
    tag           => 'icinga2::exported',
  }

}
