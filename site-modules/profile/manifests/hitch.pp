# Support for hitch TLS termination proxy
class profile::hitch {
  $frontend = lookup('hitch::frontend')
  $proxy_support = lookup('hitch::proxy_support')
  $http2_support = lookup('hitch::http2_support')

  $ocsp_dir = '/var/lib/hitch'

  if $proxy_support {
    $varnish_proxy_port = lookup('varnish::proxy_port')
    $backend            = "[::1]:${varnish_proxy_port}"
    $write_proxy_v2     = 'on'
  } else {
    $apache_http_port = lookup('apache::http_port')
    $backend          = "[::1]:${apache_http_port}"
    $write_proxy_v2   = 'off'
  }

  if $http2_support {
    $alpn_protos = 'h2,http/1.1'
  } else {
    $alpn_protos = undef
  }

  class {'::hitch':
    frontend       => $frontend,
    backend        => $backend,
    write_proxy_v2 => $write_proxy_v2,
    alpn_protos    => $alpn_protos,
    require        => File[$ocsp_dir],
  }

  file {$ocsp_dir:
    ensure => directory,
    mode   => '0700',
    owner  => $::hitch::user,
    group  => $::hitch::group,
    notify => Service[$::hitch::service_name],
  }

  # Provide virtual resources for each possible hitch TLS certificate
  # Users can realize the resource using
  #   realize(::Profile::Hitch::Ssl_Cert[$cert_name])
  $ssl_certs = keys(lookup('letsencrypt::certificates'))
  @::profile::hitch::ssl_cert {$ssl_certs:}
}
