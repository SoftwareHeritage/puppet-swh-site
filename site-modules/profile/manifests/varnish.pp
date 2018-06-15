# Varnish configuration

class profile::varnish {
  $includes_dir = '/etc/varnish/includes'
  $includes_vcl_name = 'includes.vcl'
  $includes_vcl = "/etc/varnish/${includes_vcl_name}"

  $http_port = lookup('varnish::http_port')
  $backend_http_port = lookup('varnish::backend_http_port')

  $listen = lookup('varnish::listen')
  $admin_listen = lookup('varnish::admin_listen')
  $admin_port = lookup('varnish::admin_port')
  $http2_support = lookup('varnish::http2_support')
  $secret = lookup('varnish::secret')
  $storage_type = lookup('varnish::storage_type')
  $storage_size = lookup('varnish::storage_size')
  $storage_file = lookup('varnish::storage_file')

  if $http2_support {
    $runtime_params = {
      feature => '+http2',
    }
  } else {
    $runtime_params = {}
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
  }

  ::varnish::vcl {'/etc/varnish/default.vcl':
    content => template('profile/varnish/default.vcl.erb'),
    require => Concat[$includes_vcl],
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

  include ::profile::varnish::default_vcls
}
