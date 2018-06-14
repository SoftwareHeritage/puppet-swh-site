# Definition of vcl includes

define profile::varnish::vcl_include (
  String $content,
  String $basename = $title,
  String $order = '01',
) {
  $includes_dir = $::profile::varnish::includes_dir
  $includes_vcl = $::profile::varnish::includes_vcl

  $vcl_path = "${::profile::varnish::includes_dir}/${order}_${basename}.vcl"

  ::varnish::vcl {$vcl_path:
    content => $content,
    require => File[$includes_dir],
  }

  concat::fragment {"${includes_vcl}:${basename}":
    target  => $includes_vcl,
    content => "include \"includes/${order}_${basename}.vcl\";",
    order   => $order,
    require => ::Varnish::Vcl[$vcl_path],
  }
}
