# WebApp deployment
class profile::swh::deploy::webapp {
  $conf_directory = hiera('swh::deploy::webapp::conf_directory')
  $conf_file = hiera('swh::deploy::webapp::conf_file')
  $user = hiera('swh::deploy::webapp::user')
  $group = hiera('swh::deploy::webapp::group')

  $webapp_config = hiera('swh::deploy::webapp::config')
  $conf_log_dir = hiera('swh::deploy::webapp::conf::log_dir')

  $uwsgi_listen_address = hiera('swh::deploy::webapp::uwsgi::listen')
  $uwsgi_protocol = hiera('swh::deploy::webapp::uwsgi::protocol')
  $uwsgi_workers = hiera('swh::deploy::webapp::uwsgi::workers')
  $uwsgi_max_requests = hiera('swh::deploy::webapp::uwsgi::max_requests')
  $uwsgi_max_requests_delta = hiera('swh::deploy::webapp::uwsgi::max_requests_delta')
  $uwsgi_reload_mercy = hiera('swh::deploy::webapp::uwsgi::reload_mercy')

  $swh_packages = ['python3-swh.web.ui']
  $static_dir = '/usr/lib/python3/dist-packages/swh/web/ui/static'

  $vhost_name = hiera('swh::deploy::webapp::vhost::name')
  $vhost_aliases = hiera('swh::deploy::webapp::vhost::aliases')
  $vhost_docroot = hiera('swh::deploy::webapp::vhost::docroot')
  $vhost_basic_auth_file = "${conf_directory}/http_auth"
  $vhost_basic_auth_content = hiera('swh::deploy::webapp::vhost::basic_auth_content')
  $vhost_ssl_protocol = hiera('swh::deploy::webapp::vhost::ssl_protocol')
  $vhost_ssl_honorcipherorder = hiera('swh::deploy::webapp::vhost::ssl_honorcipherorder')
  $vhost_ssl_cipher = hiera('swh::deploy::webapp::vhost::ssl_cipher')

  $locked_endpoints = hiera_array('swh::deploy::webapp::locked_endpoints')

  $endpoint_directories = $locked_endpoints.map |$endpoint| {
    { path           => "^${endpoint}",
      provider       => 'locationmatch',
      auth_type      => 'Basic',
      auth_name      => 'Software Heritage development',
      auth_user_file => $vhost_basic_auth_file,
      auth_require   => 'valid-user',
    }
  }

  include ::uwsgi

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

  file {$conf_log_dir:
    ensure => directory,
    owner  => 'root',
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
    notify  => Service['uwsgi'],
  }

  ::uwsgi::site {'swh-webapp':
    ensure   => enabled,
    settings => {
      plugin              => 'python3',
      protocol            => $uwsgi_protocol,
      socket              => $uwsgi_listen_address,
      workers             => $uwsgi_workers,
      max_requests        => $uwsgi_max_requests,
      max_requests_delta  => $uwsgi_max_requests_delta,
      worker_reload_mercy => $uwsgi_reload_mercy,
      reload_mercy        => $uwsgi_reload_mercy,
      uid                 => $user,
      gid                 => $user,
      umask               => '022',
      module              => 'swh.web.ui.main',
      callable            => 'run_from_webserver',
    }
  }

  include ::profile::ssl
  include ::profile::apache::common
  include ::apache::mod::proxy
  include ::apache::mod::headers

  ::apache::mod {'proxy_uwsgi':}

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
        url  => "uwsgi://${uwsgi_listen_address}/",
      },
    ],
    directories          => [
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

  @@::icinga2::object::service {"swh-webapp http redirect on ${::fqdn}":
    service_name  => 'swh webapp http redirect',
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

  @@::icinga2::object::service {"swh-webapp https on ${::fqdn}":
    service_name  => 'swh webapp',
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

  @@::icinga2::object::service {"swh-webapp https certificate ${::fqdn}":
    service_name  => 'swh webapp https certificate',
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

  @@::icinga2::object::service {"swh-webapp counters ${::fqdn}":
    service_name  => 'swh webapp counters',
    import        => ['generic-service'],
    host_name     => $::fqdn,
    check_command => 'http',
    vars          => {
      http_address => $vhost_name,
      http_vhost   => $vhost_name,
      http_uri     => '/api/1/stat/counters/',
      http_ssl     => true,
      http_string  => '"content":'
    },
    target        => $icinga_checks_file,
    tag           => 'icinga2::exported',
  }

  @@::icinga2::object::service {"swh-webapp content known ${::fqdn}":
    service_name  => 'swh webapp content known',
    import        => ['generic-service'],
    host_name     => $::fqdn,
    check_command => 'http',
    vars          => {
      http_address => $vhost_name,
      http_vhost   => $vhost_name,
      http_uri     => '/api/1/known/',
      http_ssl     => true,
      http_post    => 'q=8624bcdae55baeef00cd11d5dfcfa60f68710a02',
      http_string  => '"found": true',
    },
    target        => $icinga_checks_file,
    tag           => 'icinga2::exported',
  }
}
