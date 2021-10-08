# Virtual host definition for varnish

define profile::varnish::vhost (
  String $servername = $title,
  String $order = '50',
  Array[String] $aliases = [],
  String $backend_name,
  String $backend_http_host,
  String $backend_http_port,
  Boolean $websocket_support = false,
  Optional[String] $vcl_recv_extra = undef,
  Optional[String] $vcl_deliver_extra = undef,
  Variant[Undef, String, Integer[1]] $hsts_max_age = undef,
  Boolean $basic_auth = false,
  Optional[Array[String]] $basic_auth_strings = undef,
) {

  ::profile::varnish::vcl_include {$backend_name:
    order   => '01',
    content => template('profile/varnish/backend.vcl.erb'),
  }

  ::profile::varnish::vcl_include {"vhost_${servername}":
    order   => $order,
    content => template('profile/varnish/vhost.vcl.erb'),
  }
}
