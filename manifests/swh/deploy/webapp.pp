# WebApp deployment
class profile::swh::deploy::webapp {
  $conf_directory = hiera('swh::deploy::webapp::conf_directory')
  $conf_file = hiera('swh::deploy::webapp::conf_file')
  $user = hiera('swh::deploy::webapp::user')
  $group = hiera('swh::deploy::webapp::group')

  $conf_storage_class = hiera('swh::deploy::webapp::conf::storage_class')
  $conf_storage_args = hiera('swh::deploy::webapp::conf::storage_args')
  $conf_log_dir = hiera('swh::deploy::webapp::conf::log_dir')
  $conf_secret_key = hiera('swh::deploy::webapp::conf::secret_key')

  $uwsgi_listen_address = hiera('swh::deploy::webapp::uwsgi::listen')
  $uwsgi_protocol = hiera('swh::deploy::webapp::uwsgi::protocol')
  $uwsgi_workers = hiera('swh::deploy::webapp::uwsgi::workers')
  $uwsgi_max_requests = hiera('swh::deploy::webapp::uwsgi::max_requests')
  $uwsgi_max_requests_delta = hiera('swh::deploy::webapp::uwsgi::max_requests_delta')
  $uwsgi_reload_mercy = hiera('swh::deploy::webapp::uwsgi::reload_mercy')

  $swh_packages = ['python3-swh.web.ui']

  $vhost_name = hiera('swh::deploy::webapp::vhost::name')
  $vhost_docroot = hiera('swh::deploy::webapp::vhost::docroot')
  $vhost_basic_auth_file = "${conf_directory}/http_auth"
  $vhost_basic_auth_content = hiera('swh::deploy::webapp::vhost::basic_auth_content')
  $vhost_ssl_protocol = hiera('swh::deploy::webapp::vhost::ssl_protocol')
  $vhost_ssl_honorcipherorder = hiera('swh::deploy::webapp::vhost::ssl_honorcipherorder')
  $vhost_ssl_cipher = hiera('swh::deploy::webapp::vhost::ssl_cipher')

  include ::uwsgi

  package {$swh_packages:
    ensure  => latest,
    require => Apt::Source['softwareheritage'],
    notify  => [
      Service['uwsgi'],
      Exec['update-static'],
    ],
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
    content => template('profile/swh/deploy/webapp/webapp.ini.erb'),
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

  exec {'update-static':
    path        => ['/bin', '/usr/bin'],
    command     => "rsync -az --delete /usr/lib/python3/dist-packages/swh/web/ui/static/ ${vhost_docroot}/static/",
    refreshonly => true,
    require     => [
      File[$vhost_docroot],
      Package[$swh_packages],
    ],
  }

  include ::apache
  include ::apache::mod::proxy

  ::apache::mod {'proxy_uwsgi':}

  ::apache::vhost {"${vhost_name}_non-ssl":
    servername      => $vhost_name,
    port            => '80',
    docroot         => $vhost_docroot,
    redirect_status => 'permanent',
    redirect_dest   => "https://${vhost_name}/",
  }

  ::apache::vhost {"${vhost_name}_ssl":
    servername           => $vhost_name,
    port                 => '443',
    ssl                  => true,
    ssl_protocol         => $vhost_ssl_protocol,
    ssl_honorcipherorder => $vhost_ssl_honorcipherorder,
    ssl_cipher           => $vhost_ssl_cipher,
    docroot              => $vhost_docroot,
    proxy_pass           => [
      { path => '/static',
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
      { path           => '/',
        provider       => 'location',
        auth_type      => 'Basic',
        auth_name      => 'Software Heritage development',
        auth_user_file => $vhost_basic_auth_file,
        auth_require   => 'valid-user',
      },
      { path     => "${vhost_docroot}/static",
        options  => ['-Indexes'],
      },
    ],
    require              => [
      File[$vhost_basic_auth_file],
      Exec['update-static'],
    ],
  }

  file {$vhost_basic_auth_file:
    ensure  => present,
    owner   => 'root',
    group   => 'www-data',
    mode    => '0640',
    content => $vhost_basic_auth_content,
  }
}
