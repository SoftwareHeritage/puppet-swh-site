# Deployment of web-facing public Git-annex
class profile::annex_web {

  $annex_basepath =  hiera('annex::basepath')

  $annex_vhost_name = hiera('annex::vhost::name')
  $annex_vhost_docroot = hiera('annex::vhost::docroot')
  $annex_vhost_basic_auth_file = "${annex_basepath}/http_auth"
  $annex_vhost_basic_auth_content = hiera('annex::vhost::basic_auth_content')
  $annex_vhost_ssl_protocol = hiera('annex::vhost::ssl_protocol')
  $annex_vhost_ssl_honorcipherorder = hiera('annex::vhost::ssl_honorcipherorder')
  $annex_vhost_ssl_cipher = hiera('annex::vhost::ssl_cipher')
  $annex_vhost_hsts_header = hiera('annex::vhost::hsts_header')

  include ::profile::ssl
  include ::profile::apache::common

  ::apache::vhost {"${annex_vhost_name}_non-ssl":
    servername      => $annex_vhost_name,
    port            => '80',
    docroot         => $annex_vhost_docroot,
    redirect_status => 'permanent',
    redirect_dest   => "https://${annex_vhost_name}/",
  }

  $ssl_cert_name = 'star_softwareheritage_org'
  $ssl_cert = $::profile::ssl::certificate_paths[$ssl_cert_name]
  $ssl_ca   = $::profile::ssl::ca_paths[$ssl_cert_name]
  $ssl_key  = $::profile::ssl::private_key_paths[$ssl_cert_name]

  ::apache::vhost {"${annex_vhost_name}_ssl":
    servername           => $annex_vhost_name,
    port                 => '443',
    ssl                  => true,
    ssl_protocol         => $annex_vhost_ssl_protocol,
    ssl_honorcipherorder => $annex_vhost_ssl_honorcipherorder,
    ssl_cipher           => $annex_vhost_ssl_cipher,
    ssl_cert             => $ssl_cert,
    ssl_ca               => $ssl_ca,
    ssl_key              => $ssl_key,
    headers              => [$annex_vhost_hsts_header],
    docroot              => $annex_vhost_docroot,
    directories          => [{
                             'path'     => $annex_vhost_docroot,
                             'require'  => 'all granted',
                             'options'  => ['Indexes', 'FollowSymLinks', 'MultiViews'],
                             },
                             {  # hide (annex) .git directory
                             'path'     => '.*/\.git/?$',
                             'provider' => 'directorymatch',
                             'require'  => 'all denied',
                             }],
    require              => [
        File[$ssl_cert],
        File[$ssl_ca],
        File[$ssl_key],
    ],
  }

  file {"${annex_vhost_docroot}/public":
    ensure  => link,
    target  => "../annexroot/public",
    require => File[$annex_vhost_docroot],
  }

  file {$annex_vhost_basic_auth_file:
    ensure  => present,
    owner   => 'root',
    group   => 'www-data',
    mode    => '0640',
    content => '$annex_vhost_basic_auth_content',
  }


  $icinga_checks_file = '/etc/icinga2/conf.d/exported-checks.conf'

  @@::icinga2::object::service {"annex http redirect on ${::fqdn}":
    service_name  => 'annex http redirect',
    import        => ['generic-service'],
    host_name     => $::fqdn,
    check_command => 'http',
    vars          => {
      http_address => $annex_vhost_name,
      http_vhost   => $annex_vhost_name,
      http_uri     => '/',
    },
    target        => $icinga_checks_file,
    tag           => 'icinga2::exported',
  }

  @@::icinga2::object::service {"annex https on ${::fqdn}":
    service_name  => 'annex https',
    import        => ['generic-service'],
    host_name     => $::fqdn,
    check_command => 'http',
    vars          => {
      http_address    => $annex_vhost_name,
      http_vhost      => $annex_vhost_name,
      http_ssl        => true,
      http_sni        => true,
      http_uri        => '/',
      http_onredirect => sticky
    },
    target        => $icinga_checks_file,
    tag           => 'icinga2::exported',
  }

  @@::icinga2::object::service {"annex https certificate ${::fqdn}":
    service_name  => 'annex https certificate',
    import        => ['generic-service'],
    host_name     => $::fqdn,
    check_command => 'http',
    vars          => {
      http_address     => $annex_vhost_name,
      http_vhost       => $annex_vhost_name,
      http_ssl         => true,
      http_sni         => true,
      http_certificate => 60,
    },
    target        => $icinga_checks_file,
    tag           => 'icinga2::exported',
  }
}
