# WebApp deployment
class profile::swh::deploy::webapp {
  $conf_directory = lookup('swh::deploy::webapp::conf_directory')
  $conf_file = lookup('swh::deploy::webapp::conf_file')
  $user = lookup('swh::deploy::webapp::user')
  $group = lookup('swh::deploy::webapp::group')

  $webapp_config = lookup('swh::deploy::webapp::config')
  $conf_log_dir = lookup('swh::deploy::webapp::conf::log_dir')

  $backend_listen_host = lookup('swh::deploy::webapp::backend::listen::host')
  $backend_listen_port = lookup('swh::deploy::webapp::backend::listen::port')
  $backend_listen_address = "${backend_listen_host}:${backend_listen_port}"
  $backend_workers = lookup('swh::deploy::webapp::backend::workers')
  $backend_http_keepalive = lookup('swh::deploy::webapp::backend::http_keepalive')
  $backend_http_timeout = lookup('swh::deploy::webapp::backend::http_timeout')
  $backend_reload_mercy = lookup('swh::deploy::webapp::backend::reload_mercy')

  $static_dir = '/usr/lib/python3/dist-packages/swh/web/static'

  $varnish_http_port = lookup('varnish::http_port')

  $vhost_name = lookup('swh::deploy::webapp::vhost::name')
  $vhost_port = lookup('apache::http_port')
  $vhost_aliases = lookup('swh::deploy::webapp::vhost::aliases')
  $vhost_docroot = lookup('swh::deploy::webapp::vhost::docroot')
  $vhost_basic_auth_file = "${conf_directory}/http_auth"
  $vhost_basic_auth_content = lookup('swh::deploy::webapp::vhost::basic_auth_content', String, 'first', '')
  $vhost_ssl_port = lookup('apache::https_port')
  $vhost_ssl_protocol = lookup('swh::deploy::webapp::vhost::ssl_protocol')
  $vhost_ssl_honorcipherorder = lookup('swh::deploy::webapp::vhost::ssl_honorcipherorder')
  $vhost_ssl_cipher = lookup('swh::deploy::webapp::vhost::ssl_cipher')

  $production_db_dir = lookup('swh::deploy::webapp::production_db_dir')
  $production_db_file = lookup('swh::deploy::webapp::production_db')

  $locked_endpoints = lookup('swh::deploy::webapp::locked_endpoints', Array, 'unique')

  $endpoint_directories = $locked_endpoints.map |$endpoint| {
    { path           => "^${endpoint}",
      provider       => 'locationmatch',
      auth_type      => 'Basic',
      auth_name      => 'Software Heritage development',
      auth_user_file => $vhost_basic_auth_file,
      auth_require   => 'valid-user',
    }
  }

  # Install the necessary deps
  ::profile::swh::deploy::install_web_deps { 'swh-web':
    services      => ['gunicorn-swh-webapp'],
    backport_list => 'swh::deploy::webapp::backported_packages',
    swh_packages  => ['python3-swh.web'],
  }

  include ::gunicorn

  file {$conf_directory:
    ensure => directory,
    owner  => 'root',
    group  => $group,
    mode   => '0755',
  }

  file {$conf_log_dir:
    ensure => directory,
    owner  => 'root',
    group  => $group,
    mode   => '0770',
  }

  file {"$conf_log_dir/swh-web.log":
    ensure => present,
    owner  => $user,
    group  => $group,
    mode   => '0770',
  }

  file {$vhost_docroot:
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
    content => inline_template("<%= @webapp_config.to_yaml %>\n"),
    notify  => Service['gunicorn-swh-webapp'],
  }

  file {$production_db_dir:
    ensure => directory,
    owner  => $user,
    group  => $group,
    mode   => '0755',
  }

  file {$production_db_file:
    ensure => present,
    owner  => $user,
    group  => $group,
    mode   => '0664',
  }

  ::gunicorn::instance {'swh-webapp':
    ensure             => enabled,
    user               => $user,
    group              => $group,
    executable         => 'django.core.wsgi:get_wsgi_application()',
    config_base_module => 'swh.web.gunicorn_config',
    settings           => {
      bind               => $backend_listen_address,
      workers            => $backend_workers,
      worker_class       => 'sync',
      timeout            => $backend_http_timeout,
      graceful_timeout   => $backend_reload_mercy,
      keepalive          => $backend_http_keepalive,
    },
    environment        => {
      'DJANGO_SETTINGS_MODULE' => 'swh.web.settings.production',
    }
  }

  include ::profile::apache::common
  include ::apache::mod::proxy
  include ::apache::mod::headers

  ::apache::vhost {"${vhost_name}_non-ssl":
    servername      => $vhost_name,
    serveraliases   => $vhost_aliases,
    port            => $vhost_port,
    docroot         => $vhost_docroot,
    proxy_pass      => [
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
    directories     => [
      { path     => '/api',
        provider => 'location',
        allow    => 'from all',
        satisfy  => 'Any',
        headers  => ['add Access-Control-Allow-Origin "*"'],
      },
      { path    => $static_dir,
        options => ['-Indexes'],
      },
    ] + $endpoint_directories,
    aliases         => [
      { alias => '/static',
        path  => $static_dir,
      },
      { alias => '/robots.txt',
        path  => "${static_dir}/robots.txt",
      },
    ],
    # work around fix for CVE-2019-0220 introduced in Apache2 2.4.25-3+deb9u7
    custom_fragment => 'MergeSlashes off',
    require         => [
      File[$vhost_basic_auth_file],
    ],
  }

  $ssl_cert_names = ['star_softwareheritage_org', 'star_internal_softwareheritage_org']

  include ::profile::hitch
  each($ssl_cert_names) |$ssl_cert_name| {
    realize(::Profile::Hitch::Ssl_cert[$ssl_cert_name])
  }

  include ::profile::varnish
  ::profile::varnish::vhost {$vhost_name:
    aliases      => $vhost_aliases,
    hsts_max_age => lookup('strict_transport_security::max_age'),
  }

  if $endpoint_directories {
    file {$vhost_basic_auth_file:
      ensure  => present,
      owner   => 'root',
      group   => 'www-data',
      mode    => '0640',
      content => $vhost_basic_auth_content,
    }
  } else {
    file {$vhost_basic_auth_file:
      ensure  => absent,
    }
  }

  $icinga_checks_file = lookup('icinga2::exported_checks::filename')

  @@::icinga2::object::service {"swh-webapp http redirect on ${::fqdn}":
    service_name  => 'swh webapp http redirect',
    import        => ['generic-service'],
    host_name     => $::fqdn,
    check_command => 'http',
    vars          => {
      http_address => $vhost_name,
      http_vhost   => $vhost_name,
      http_port    => $varnish_http_port,
      http_uri     => '/',
    },
    target        => $icinga_checks_file,
    tag           => 'icinga2::exported',
  }

  @@::icinga2::object::service {"swh-webapp https on ${::fqdn}":
    service_name  => 'swh webapp',
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

  @@::icinga2::object::service {"swh-webapp https certificate ${::fqdn}":
    service_name  => 'swh webapp https certificate',
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

  include ::profile::swh::deploy::webapp::icinga_checks
}
