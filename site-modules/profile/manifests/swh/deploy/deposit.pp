# Deployment of the swh.deposit server

class profile::swh::deploy::deposit {
  $config_directory = lookup('swh::deploy::deposit::config_directory')
  $config_file = lookup('swh::deploy::deposit::config_file')
  $user = lookup('swh::deploy::deposit::user')
  $group = lookup('swh::deploy::deposit::group')
  $conf_hiera = lookup('swh::deploy::deposit::config')

  $static_dir = '/usr/lib/python3/dist-packages/swh/deposit/static'

  $backend_listen_host = lookup('swh::deploy::deposit::backend::listen::host')
  $backend_listen_port = lookup('swh::deploy::deposit::backend::listen::port')
  $backend_listen_address = "${backend_listen_host}:${backend_listen_port}"

  $backend_workers = lookup('swh::deploy::deposit::backend::workers')
  $backend_http_keepalive = lookup('swh::deploy::deposit::backend::http_keepalive')
  $backend_http_timeout = lookup('swh::deploy::deposit::backend::http_timeout')
  $backend_reload_mercy = lookup('swh::deploy::deposit::backend::reload_mercy')

  $vhost_url = lookup('swh::deploy::deposit::url')

  $cert_name = lookup('swh::deploy::deposit::vhost::letsencrypt_cert')
  $vhosts = lookup('letsencrypt::certificates')[$cert_name]['domains']

  $full_conf = $conf_hiera + {allowed_hosts => $vhosts}

  if $swh_hostname['fqdn'] in $vhosts {
    $vhost_name =  $swh_hostname['fqdn']
  } else {
    $vhost_name = $vhosts[0]
  }
  $vhost_aliases = delete($vhosts, $vhost_name)

  $vhost_port = lookup('apache::http_port')
  $vhost_docroot = "/var/www/${vhost_name}"
  $vhost_basic_auth_file = "${config_directory}/http_auth"
  # swh::deploy::deposit::vhost::basic_auth_content in private
  $vhost_basic_auth_content = lookup('swh::deploy::deposit::vhost::basic_auth_content')
  $vhost_access_log_format = lookup('swh::deploy::deposit::vhost::access_log_format')
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
    swh_packages  => ['python3-swh.deposit'],
    ensure        => present,
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
    content => inline_template("<%= @full_conf.to_yaml %>\n"),
    notify  => Service['gunicorn-swh-deposit'],
  }

  file {$media_root_directory:
    ensure => directory,
    owner  => $user,
    group  => $group,
    mode   => '2750',
  }

  $sentry_dsn = lookup("swh::deploy::deposit::sentry_dsn", Optional[String], 'first', undef)
  $sentry_environment = lookup("swh::deploy::deposit::sentry_environment", Optional[String], 'first', undef)
  $sentry_swh_package = lookup("swh::deploy::deposit::sentry_swh_package", Optional[String], 'first', undef)

  ::gunicorn::instance {'swh-deposit':
    ensure     => enabled,
    user       => $user,
    group      => $group,
    executable => 'django.core.wsgi:get_wsgi_application()',
    config_base_module => 'swh.deposit.gunicorn_config',
    environment => {
      'SWH_CONFIG_FILENAME'    => $config_file,
      'DJANGO_SETTINGS_MODULE' => 'swh.deposit.settings.production',
      'SWH_SENTRY_DSN'         => $sentry_dsn,
      'SWH_SENTRY_ENVIRONMENT' => $sentry_environment,
      'SWH_MAIN_PACKAGE'       => $sentry_swh_package,
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
    access_log_format => $vhost_access_log_format,
    require       => [
      File[$vhost_basic_auth_file],
    ]
  }

  file {$vhost_basic_auth_file:
    ensure  => present,
    owner   => 'root',
    group   => 'www-data',
    mode    => '0640',
    content => $vhost_basic_auth_content,
  }

  $icinga_checks_file = lookup('icinga2::exported_checks::filename')

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

  # Install deposit end-to-end checks
  @@profile::icinga2::objects::e2e_checks_deposit {"End-to-end Deposit Test(s) in ${environment}":
    deposit_server        => lookup('swh::deploy::deposit::e2e::server'),
    deposit_user          => lookup('swh::deploy::deposit::e2e::user'),
    deposit_pass          => lookup('swh::deploy::deposit::e2e::password'),
    deposit_collection    => lookup('swh::deploy::deposit::e2e::collection'),
    deposit_poll_interval => lookup('swh::deploy::deposit::e2e::poll_interval'),
    deposit_archive       => lookup('swh::deploy::deposit::e2e:archive'),
    deposit_metadata      => lookup('swh::deploy::deposit::e2e:metadata'),
    environment           => $environment,
  }

  include profile::filebeat
  # To remove when cleanup is done
  file {'/etc/filebeat/inputs.d/deposit-non-ssl-access.yml':
    ensure => absent,
  }
  profile::filebeat::log_input { "${vhost_name}-non-ssl-access":
    paths  => [ "/var/log/apache2/${vhost_name}_non-ssl_access.log" ],
    fields => {
      'apache_log_type' => 'access_log',
      'environment'     => $environment,
      'vhost'           => $vhost_name,
      'application'     => 'deposit',
    },
  }

}
