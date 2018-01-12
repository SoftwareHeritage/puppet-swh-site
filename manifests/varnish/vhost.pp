# Virtual host definition for varnish

define profile::varnish::vhost (
  String $servername = $title,
  String $order = '50',
  Array[String] $aliases = [],
  Optional[String] $vcl_recv_extra = undef,
  Optional[String] $vcl_deliver_extra = undef,
  Optional[String] $hsts_max_age = undef,
) {
  ::profile::varnish::vcl_include {"vhost_${servername}":
    order   => $order,
    content => template('profile/varnish/vhost.vcl.erb'),
  }
}
