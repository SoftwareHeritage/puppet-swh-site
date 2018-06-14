# Default VCLs included with the varnish profile

class profile::varnish::default_vcls {
  ::profile::varnish::vcl_include {'backend_default':
    order   => '01',
    content => template('profile/varnish/backend_default.vcl.erb'),
  }

  ::profile::varnish::vcl_include {'synth_redirect':
    order   => '10',
    content => file('profile/varnish/synth_redirect.vcl'),
  }
}
