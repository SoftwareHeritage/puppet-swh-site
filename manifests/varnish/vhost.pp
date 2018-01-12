# Virtual host definition for varnish

define profile::varnish::vhost (
  String $servername = $title,
  String $order = '50',
  Array[String] $aliases = [],
  String $extra_recv_vcl = '',
  String $extra_deliver_vcl = '',
  String $hsts_max_age = undef,
) {
  ::profile::varnish::vcl_include {"vhost_${servername}":
    order   => $order,
    content => template('profile/varnish/vhost.vcl.erb'),
  }
}
