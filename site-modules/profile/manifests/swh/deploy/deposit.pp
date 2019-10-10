# Deployment of the swh.deposit server

class profile::swh::deploy::deposit {
  $config_directory = lookup('swh::deploy::deposit::config_directory')
  $config_file = lookup('swh::deploy::deposit::config_file')
  $user = lookup('swh::deploy::deposit::user')
  $group = lookup('swh::deploy::deposit::group')
  $swh_conf_raw = lookup('swh::deploy::deposit::config')

  $static_dir = '/usr/lib/python3/dist-packages/swh/deposit/static'

  $backend_listen_host = lookup('swh::deploy::deposit::backend::listen::host')
  $backend_listen_port = lookup('swh::deploy::deposit::backend::listen::port')
  $backend_listen_address = "${backend_listen_host}:${backend_listen_port}"

  $backend_workers = lookup('swh::deploy::deposit::backend::workers')
  $backend_http_keepalive = lookup('swh::deploy::deposit::backend::http_keepalive')
  $backend_http_timeout = lookup('swh::deploy::deposit::backend::http_timeout')
  $backend_reload_mercy = lookup('swh::deploy::deposit::backend::reload_mercy')

  $vhost_url = lookup('swh::deploy::deposit::url')
  $vhost_name = lookup('swh::deploy::deposit::vhost::name')
  $vhost_port = lookup('apache::http_port')
  $vhost_aliases = lookup('swh::deploy::deposit::vhost::aliases')
  $vhost_docroot = lookup('swh::deploy::deposit::vhost::docroot')
  $vhost_basic_auth_file = "${config_directory}/http_auth"
  # swh::deploy::deposit::vhost::basic_auth_content in private
  $vhost_basic_auth_content = lookup('swh::deploy::deposit::vhost::basic_auth_content')
  $vhost_ssl_port = lookup('apache::https_port')
  $vhost_ssl_protocol = lookup('swh::deploy::deposit::vhost::ssl_protocol')
  $vhost_ssl_honorcipherorder = lookup('swh::deploy::deposit::vhost::ssl_honorcipherorder')
  $vhost_ssl_cipher = lookup('swh::deploy::deposit::vhost::ssl_cipher')
  $locked_endpoints = lookup('swh::deploy::deposit::locked_endpoints', Array, 'unique')

  $media_root_directory = lookup('swh::deploy::deposit::media_root_directory')

  include ::gunicorn

  # Install the necessary deps
  ::profile::swh::deploy::install_web_deps { 'swh-deposit':
    services      => ['gunicorn-swh-deposit'],
    backport_list => 'swh::deploy::deposit::backported_packages',
    # FIXME: should be fixed in the deposit package
    swh_packages  => ['python3-django', 'python3-djangorestframework', 'python3-swh.deposit'],
  }

  file {$config_directory:
    ensure => directory,
    owner  => 'root',
    group  => $group,
    mode   => '0755',
  }

  # swh's configuration part (upload size, etc...)
  file {$config_file:
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

  ::gunicorn::instance {'swh-deposit':
    ensure     => enabled,
    user       => $user,
    group      => $group,
    executable => 'django.core.wsgi:get_wsgi_application()',
    environment => {
      'SWH_CONFIG_FILENAME'    => $config_file,
      'DJANGO_SETTINGS_MODULE' => 'swh.deposit.settings.production',
    },
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

  include ::profile::apache::common
  include ::apache::mod::proxy
  include ::apache::mod::headers

  ::apache::vhost {"${vhost_name}_non-ssl":
    servername    => $vhost_name,
    serveraliases => $vhost_aliases,
    port          => $vhost_port,
    docroot       => $vhost_docroot,
    proxy_pass    => [
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
    directories   => [
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
    aliases       => [
      { alias => '/static',
        path  => $static_dir,
      },
      { alias => '/robots.txt',
        path  => "${static_dir}/robots.txt",
      },
    ],
    require       => [
      File[$vhost_basic_auth_file],
    ]
  }

  $ssl_cert_name = 'star_softwareheritage_org'

  include ::profile::hitch
  realize(::Profile::Hitch::Ssl_cert[$ssl_cert_name])

  include ::profile::varnish
  $url_scheme = split($vhost_url, ':')[0]

  if $url_scheme == 'https' {
    ::profile::varnish::vhost {$vhost_name:
      aliases      => $vhost_aliases,
      hsts_max_age => lookup('strict_transport_security::max_age'),
    }
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
      http_port    => $vhost_port,
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
      http_port       => $vhost_ssl_port,
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
      http_port        => $vhost_ssl_port,
      http_ssl         => true,
      http_sni         => true,
      http_certificate => 60,
    },
    target        => $icinga_checks_file,
    tag           => 'icinga2::exported',
  }

}
