# WebApp deployment
class profile::swh::deploy::webapp {
  $conf_directory = lookup('swh::deploy::webapp::conf_directory')
  $conf_file = lookup('swh::deploy::webapp::conf_file')
  $user = lookup('swh::deploy::webapp::user')
  $group = lookup('swh::deploy::webapp::group')

  $webapp_config = lookup('swh::deploy::webapp::config')
  $conf_log_dir = lookup('swh::deploy::webapp::conf::log_dir')

  $webapp_settings_module = lookup('swh::deploy::webapp::django_settings_module')
  $backend_listen_host = lookup('swh::deploy::webapp::backend::listen::host')
  $backend_listen_port = lookup('swh::deploy::webapp::backend::listen::port')
  $backend_listen_address = "${backend_listen_host}:${backend_listen_port}"
  $backend_workers = lookup('swh::deploy::webapp::backend::workers')
  $backend_http_keepalive = lookup('swh::deploy::webapp::backend::http_keepalive')
  $backend_http_timeout = lookup('swh::deploy::webapp::backend::http_timeout')
  $backend_reload_mercy = lookup('swh::deploy::webapp::backend::reload_mercy')

  $static_dir = '/usr/share/swh/web/static'

  $cert_name = lookup('swh::deploy::webapp::vhost::letsencrypt_cert')
  $vhosts = lookup('letsencrypt::certificates')[$cert_name]['domains']

  $full_webapp_config = $webapp_config + {allowed_hosts => $vhosts}

  if $swh_hostname['fqdn'] in $vhosts {
    $vhost_name =  $swh_hostname['fqdn']
  } else {
    $vhost_name = $vhosts[0]
  }
  $vhost_aliases = delete($vhosts, $vhost_name)

  $vhost_access_log_format = lookup('swh::deploy::webapp::vhost::access_log_format')
  $vhost_port = lookup('apache::http_port')
  $vhost_docroot = "/var/www/${vhost_name}"
  $vhost_basic_auth_file = "${conf_directory}/http_auth"
  $vhost_basic_auth_content = lookup('swh::deploy::webapp::vhost::basic_auth_content', String, 'first', '')

  # Note that it's required by the ::profile::swh::deploy::webapp::icinga_checks
  $vhost_ssl_port = lookup('apache::https_port')

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
  $logfile = "${conf_log_dir}/swh-web.log"
  $pidfile = "/var/run/gunicorn/swh-webapp/pidfile"

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

  file {$logfile:
    ensure => present,
    owner  => $user,
    group  => $group,
    mode   => '0770',
  }

  # Template uses:
  # $logfile
  # $user
  # $group
  # $pidfile
  file {'/etc/logrotate.d/swh-webapp':
    ensure  => file,
    owner   => $user,
    group   => $group,
    mode    => '0644',
    content => template('profile/swh/logrotate-webapp.conf.erb'),
    require => File[$logfile],
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
    content => inline_template("<%= @full_webapp_config.to_yaml %>\n"),
    notify  => Service['gunicorn-swh-webapp'],
  }

  $storage_cfg = $full_webapp_config['storage']
  if $storage_cfg['cls'] == 'cassandra' {
    include ::profile::swh::deploy::storage_cassandra
  }

  $sentry_dsn = lookup('swh::deploy::webapp::sentry_dsn', Optional[String], 'first', undef)
  $sentry_environment = lookup('swh::deploy::webapp::sentry_environment', Optional[String], 'first', undef)
  $sentry_swh_package = lookup('swh::deploy::webapp::sentry_swh_package', Optional[String], 'first', undef)

  ::gunicorn::instance {'swh-webapp':
    ensure             => enabled,
    user               => $user,
    group              => $group,
    executable         => 'django.core.wsgi:get_wsgi_application()',
    config_base_module => 'swh.web.gunicorn_config',
    settings           => {
      bind             => $backend_listen_address,
      workers          => $backend_workers,
      worker_class     => 'sync',
      timeout          => $backend_http_timeout,
      graceful_timeout => $backend_reload_mercy,
      keepalive        => $backend_http_keepalive,
    },
    environment        => {
      'DJANGO_SETTINGS_MODULE' => $webapp_settings_module,
      'SWH_SENTRY_DSN'         => $sentry_dsn,
      'SWH_SENTRY_ENVIRONMENT' => $sentry_environment,
      'SWH_MAIN_PACKAGE'       => $sentry_swh_package,
    },
  }

  include ::profile::apache::common
  include ::apache::mod::proxy
  include ::apache::mod::headers

  ::apache::vhost {"${vhost_name}_non-ssl":
    servername        => $vhost_name,
    serveraliases     => $vhost_aliases,
    port              => $vhost_port,
    docroot           => $vhost_docroot,
    proxy_pass        => [
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
    directories       => [
      { path    => $static_dir,
        options => ['-Indexes'],
      },
    ] + $endpoint_directories,
    aliases           => [
      { alias => '/static',
        path  => $static_dir,
      },
      { alias => '/robots.txt',
        path  => "${static_dir}/robots.txt",
      },
    ],
    # work around fix for CVE-2019-0220 introduced in Apache2 2.4.25-3+deb9u7
    custom_fragment   => 'MergeSlashes off',
    require           => [
      File[$vhost_basic_auth_file],
    ],
    access_log_format => $vhost_access_log_format,
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

  include ::profile::swh::deploy::webapp::icinga_checks

  profile::prometheus::export_scrape_config {"swh-webapp_${fqdn}":
    job          => 'swh-webapp',
    target       => "${vhost_name}:${vhost_ssl_port}",
    scheme       => 'https',
    metrics_path => '/metrics/prometheus',
    labels       => {
      vhost_name => $vhost_name,
    },
  }

  include profile::filebeat
  # To remove when cleanup is done
  file {'/etc/filebeat/inputs.d/webapp-non-ssl-access.yml':
    ensure => absent,
  }
  profile::filebeat::log_input { "${vhost_name}-non-ssl-access":
    paths  => [ "/var/log/apache2/${vhost_name}_non-ssl_access.log" ],
    fields => {
      'apache_log_type' => 'access_log',
      'environment'     => $environment,
      'vhost'           => $vhost_name,
      'application'     => 'webapp',
    },
  }

  # This variable should be true only for a single instance per deployment
  $timers_enabled = lookup('swh::deploy::webapp::timers_enabled')

  $sync_mailmaps_dbsetting = 'swh::deploy::webapp::sync_mailmaps::db'
  $sync_mailmaps_service = lookup("${sync_mailmaps_dbsetting}::service_name")

  $pgpass_ensure = $timers_enabled ? {
    true    => 'present',
    default => 'absent',
  }

  $pg_service = '/home/swhwebapp/.pg_service.conf'
  file {$pg_service:
    ensure  => 'present',
    owner   => $user,
    group   => $group,
    mode    => '0644',
  }

  ['host', 'port', 'user', 'dbname'].each |$setting| {
    ini_setting {"swhwebapp:pg_service.conf:${sync_mailmaps_service}:${setting}":
      ensure  => $pgpass_ensure,
      path    => $pg_service,
      section => $sync_mailmaps_service,
      setting => $setting,
      value   => lookup("${sync_mailmaps_dbsetting}::${setting}"),
      require => File[$pg_service],
    }
  }

  $pgpass_header = join(
    ['host', 'port', 'user', 'dbname'].map |$setting| {
      lookup("${sync_mailmaps_dbsetting}::${setting}")
    },
    ':',
  )
  $pgpass_password = lookup("${sync_mailmaps_dbsetting}::password")

  $pgpass = '/home/swhwebapp/.pgpass'
  file {$pgpass:
    ensure  => 'present',
    owner   => $user,
    group   => $group,
    mode    => '0400',
  }

  file_line {"swhwebapp:pgpass:${sync_mailmaps_service}":
    ensure  => $pgpass_ensure,
    path    => $pgpass,
    line    => "${pgpass_header}:${pgpass_password}",
    match   => "^${pgpass_header}:",
    require => File[$pgpass],
  }

  ['update-savecodenow-statuses', 'sync-mailmaps'].each |$short_name| {
    $service_basename = "swh-webapp-${short_name}"
    $unit_template = "profile/swh/deploy/webapp/${short_name}.service.erb"
    $timer_name = "${service_basename}.timer"
    $timer_template = "profile/swh/deploy/webapp/${short_name}.timer.erb"

    # Template uses variables
    #  - $user
    #  - $group
    #  - $webapp_settings_module
    #  - $service_basename
    #  - $sync_mailmaps_service (for sync-mailmaps)

    ::systemd::timer { $timer_name:
      timer_content    => template($timer_template),
      service_content  => template($unit_template),
      active           => $timers_enabled,
      enable           => $timers_enabled,
      require          => Profile::Swh::Deploy::Install_web_deps['swh-web'],
    }
  }
}
