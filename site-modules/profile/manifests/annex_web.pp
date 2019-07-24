# Deployment of web-facing public Git-annex
class profile::annex_web {

  $annex_basepath =  lookup('annex::basepath')

  $annex_vhost_name = lookup('annex::vhost::name')
  $annex_vhost_docroot = lookup('annex::vhost::docroot')
  $annex_vhost_basic_auth_file = "${annex_basepath}/http_auth"
  $annex_vhost_provenance_basic_auth_file = "${annex_basepath}/http_auth_provenance"
  $annex_vhost_basic_auth_content = lookup('annex::vhost::basic_auth_content')
  $annex_vhost_provenance_basic_auth_content = lookup('annex::vhost::provenance::basic_auth_content')
  $annex_vhost_ssl_protocol = lookup('annex::vhost::ssl_protocol')
  $annex_vhost_ssl_honorcipherorder = lookup('annex::vhost::ssl_honorcipherorder')
  $annex_vhost_ssl_cipher = lookup('annex::vhost::ssl_cipher')
  $annex_vhost_hsts_header = lookup('annex::vhost::hsts_header')

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
  $ssl_chain   = $::profile::ssl::chain_paths[$ssl_cert_name]
  $ssl_key  = $::profile::ssl::private_key_paths[$ssl_cert_name]

  ::apache::vhost {"${annex_vhost_name}_ssl":
    servername           => $annex_vhost_name,
    port                 => '443',
    ssl                  => true,
    ssl_protocol         => $annex_vhost_ssl_protocol,
    ssl_honorcipherorder => $annex_vhost_ssl_honorcipherorder,
    ssl_cipher           => $annex_vhost_ssl_cipher,
    ssl_cert             => $ssl_cert,
    ssl_chain            => $ssl_chain,
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
                             },
                             {  # 'basic' provenance-index authentication
                             'path'           => "$annex_vhost_docroot/provenance-index",
                             'auth_type'      => 'basic',
                             'auth_name'      => 'SWH - Password Required',
                             'auth_user_file' => $annex_vhost_provenance_basic_auth_file,
                             'auth_require'   => 'valid-user',
                             'index_options'  => 'FancyIndexing',
                             'readme_name'    => 'readme.txt',
                             },
                            ],
    require              => [
        File[$ssl_cert],
        File[$ssl_chain],
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
    # FIXME: this seems wrong, should be double quote to expand the variable
    # don't want to break existing behavior though
    content => '$annex_vhost_basic_auth_content',
  }

  file {$annex_vhost_provenance_basic_auth_file:
    ensure  => present,
    owner   => 'root',
    group   => 'www-data',
    mode    => '0640',
    content => "$annex_vhost_provenance_basic_auth_content",
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
