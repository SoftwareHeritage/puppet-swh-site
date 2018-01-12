# Support for hitch TLS termination proxy
class profile::hitch {
  $frontend = hiera('hitch::frontend')
  $proxy_support = hiera('hitch::proxy_support')

  if $proxy_support {
    $varnish_proxy_port = hiera('varnish::proxy_port')
    $backend            = "[::1]:${varnish_proxy_port}"
    $write_proxy_v2     = 'on'
  } else {
    $apache_http_port = hiera('apache::http_port')
    $backend          = "[::1]:${apache_http_port}"
    $write_proxy_v2   = 'off'
  }

  class {'::hitch':
    frontend       => $frontend,
    backend        => $backend,
    write_proxy_v2 => $write_proxy_v2,
  }
}
