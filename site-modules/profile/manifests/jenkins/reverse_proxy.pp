class profile::jenkins::reverse_proxy {
  $jenkins_backend_url = lookup('jenkins::backend::url')

  include ::profile::ssl
  include ::profile::apache::common
  include ::apache::mod::proxy

  $jenkins_vhost_name = lookup('jenkins::vhost::name')
  $jenkins_vhost_docroot = '/var/www/html'
  $jenkins_vhost_ssl_protocol = lookup('jenkins::vhost::ssl_protocol')
  $jenkins_vhost_ssl_honorcipherorder = lookup('jenkins::vhost::ssl_honorcipherorder')
  $jenkins_vhost_ssl_cipher = lookup('jenkins::vhost::ssl_cipher')
  $jenkins_vhost_hsts_header = lookup('jenkins::vhost::hsts_header')


  ::apache::vhost {"${jenkins_vhost_name}_non-ssl":
    servername      => $jenkins_vhost_name,
    port            => '80',
    docroot         => $jenkins_vhost_docroot,
    manage_docroot  => false,
    redirect_status => 'permanent',
    redirect_dest   => "https://${jenkins_vhost_name}/",
  }

  $ssl_cert_name = 'star_softwareheritage_org'
  $ssl_cert = $::profile::ssl::certificate_paths[$ssl_cert_name]
  $ssl_chain   = $::profile::ssl::chain_paths[$ssl_cert_name]
  $ssl_key  = $::profile::ssl::private_key_paths[$ssl_cert_name]

  ::apache::vhost {"${jenkins_vhost_name}_ssl":
    servername            => $jenkins_vhost_name,
    port                  => '443',
    ssl                   => true,
    ssl_protocol          => $jenkins_vhost_ssl_protocol,
    ssl_honorcipherorder  => $jenkins_vhost_ssl_honorcipherorder,
    ssl_cipher            => $jenkins_vhost_ssl_cipher,
    ssl_cert              => $ssl_cert,
    ssl_chain             => $ssl_chain,
    ssl_key               => $ssl_key,
    headers               => [$jenkins_vhost_hsts_header],
    docroot               => $jenkins_vhost_docroot,
    manage_docroot        => false,

    # settings from https://wiki.jenkins.io/display/JENKINS/Running+Jenkins+behind+Apache
    allow_encoded_slashes => 'nodecode',
    proxy_pass            => [
      { path     => '/',
        url      => $jenkins_backend_url,
        keywords => ['nocanon'],
      },
    ],
    request_headers       => [
      'set X-Forwarded-Proto "https"',
      'set X-Forwarded-Port "443"',
    ],
    require               => [
        File[$ssl_cert],
        File[$ssl_chain],
        File[$ssl_key],
    ],
  }

  $icinga_checks_file = '/etc/icinga2/conf.d/exported-checks.conf'

  @@::icinga2::object::service {"jenkins http redirect on ${::fqdn}":
    service_name  => 'jenkins http redirect',
    import        => ['generic-service'],
    host_name     => $::fqdn,
    check_command => 'http',
    vars          => {
      http_address => $jenkins_vhost_name,
      http_vhost   => $jenkins_vhost_name,
      http_uri     => '/',
    },
    target        => $icinga_checks_file,
    tag           => 'icinga2::exported',
  }

  @@::icinga2::object::service {"jenkins https on ${::fqdn}":
    service_name  => 'jenkins https',
    import        => ['generic-service'],
    host_name     => $::fqdn,
    check_command => 'http',
    vars          => {
      http_address => $jenkins_vhost_name,
      http_vhost   => $jenkins_vhost_name,
      http_ssl     => true,
      http_sni     => true,
      http_uri     => '/',
      http_string  => 'Jenkins',
    },
    target        => $icinga_checks_file,
    tag           => 'icinga2::exported',
  }

  @@::icinga2::object::service {"jenkins https certificate ${::fqdn}":
    service_name  => 'jenkins https certificate',
    import        => ['generic-service'],
    host_name     => $::fqdn,
    check_command => 'http',
    vars          => {
      http_address     => $jenkins_vhost_name,
      http_vhost       => $jenkins_vhost_name,
      http_ssl         => true,
      http_sni         => true,
      http_certificate => 60,
    },
    target        => $icinga_checks_file,
    tag           => 'icinga2::exported',
  }
}
