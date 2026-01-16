# Varnish configuration

class profile::varnish {
  $includes_dir = '/etc/varnish/includes'
  $includes_vcl_name = 'includes.vcl'
  $includes_vcl = "/etc/varnish/${includes_vcl_name}"

  $http_port = lookup('varnish::http_port')
  $backend_http_port = lookup('varnish::backend_http_port')

  $config_listen = lookup('varnish::listen')
  $admin_listen = lookup('varnish::admin_listen')
  $admin_port = lookup('varnish::admin_port')
  $http2_support = lookup('varnish::http2_support')
  $secret = lookup('varnish::secret')
  $storage_type = lookup('varnish::storage_type')
  $storage_size = lookup('varnish::storage_size')
  $storage_file = lookup('varnish::storage_file')
  $useragent_blocklist = lookup('varnish::useragent_blocklist')
  $enable_anubis = lookup('varnish::enable_anubis')

  if $http2_support {
    $runtime_params = {
      feature => '+http2',
    }
  } else {
    $runtime_params = {}
  }

  $anubis_socket_name = 'behind_anubis'

  if $enable_anubis {
    include ::profile::anubis::varnish

    $anubis_backend_listen = lookup('varnish::anubis_backend_listen')
    $anubis_backend_port = lookup('varnish::anubis_backend_port')
    $anubis_listen_host = lookup('anubis::varnish::listen_host')
    $anubis_listen_port = lookup('anubis::varnish::listen_port')

    $listen = $config_listen + [
      "${anubis_socket_name}=${anubis_backend_listen}:${anubis_backend_port},HTTP"
    ]

    ::profile::varnish::vcl_include {'anubis':
      order   => '01',
      content => template('profile/varnish/anubis.vcl.erb'),
    }
  } else {
    $listen = $config_listen
  }

  $extra_packages = ["varnish-modules"];
  package {$extra_packages:
    ensure => installed,
  }

  class {'::varnish':
    addrepo        => false,
    listen         => $listen,
    admin_listen   => $admin_listen,
    admin_port     => $admin_port,
    secret         => $secret,
    storage_type   => $storage_type,
    storage_size   => $storage_size,
    storage_file   => $storage_file,
    runtime_params => $runtime_params,
    vcl_reload_cmd => '/usr/share/varnish/varnishreload',
  }

  ::varnish::vcl {'/etc/varnish/default.vcl':
    content => template('profile/varnish/default.vcl.erb'),
    require => [
      Concat[$includes_vcl],
      Package[$extra_packages],
    ],
  }

  file {$includes_dir:
    ensure  => directory,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    require => Class['varnish::install'],
    notify  => Exec['vcl_reload'],
  }

  concat {$includes_vcl:
    ensure         => present,
    owner          => 'root',
    group          => 'root',
    mode           => '0644',
    ensure_newline => true,
    require        => Class['varnish::install'],
    notify         => Exec['vcl_reload'],
  }

  concat::fragment {"${includes_vcl}:header":
    target  => $includes_vcl,
    content => "# File managed with puppet (module profile::varnish)\n# All modifications will be lost\n\n",
    order   => '00',
  }

  ::profile::varnish::vcl_include {'early_vcl_recv':
    order   => '00',
    content => file('profile/varnish/early_vcl_recv.vcl'),
  }

  ::profile::varnish::vcl_include {'useragent_blocklist':
    order   => '20',
    content => template('profile/varnish/useragent_blocklist.vcl.erb'),
  }

  ::profile::varnish::vcl_include {'synth_redirect':
    order   => '10',
    content => file('profile/varnish/synth_redirect.vcl'),
  }

  ::profile::varnish::vcl_include {'unknown_vhost_then_forbidden_access':
    order   => '99',
    content => file('profile/varnish/unknown_vhost_then_forbidden_access.vcl'),
  }

  include profile::prometheus::varnish

  include profile::filebeat
  profile::filebeat::log_input { "varnishncsa.log":
    paths  => [ "/var/log/varnish/varnishncsa.log" ],
    fields => {
      'log_type'        => 'varnish',
      'environment'     => $environment,
      'application'     => 'varnishncsa',
    },
  }

}
