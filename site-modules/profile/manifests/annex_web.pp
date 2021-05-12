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

  include ::profile::apache::common

  exec {"create ${annex_vhost_docroot}":
    creates => $annex_vhost_docroot,
    command => "mkdir -p ${annex_vhost_docroot}",
    path    => ['/bin', '/usr/bin', '/sbin', '/usr/sbin'],
  }

  ::apache::vhost {"${annex_vhost_name}_non-ssl":
    servername      => $annex_vhost_name,
    port            => '80',
    docroot         => $annex_vhost_docroot,
    redirect_status => 'permanent',
    redirect_dest   => "https://${annex_vhost_name}/",
  }

  ::profile::letsencrypt::certificate {$annex_vhost_name:}
  $cert_paths = ::profile::letsencrypt::certificate_paths($annex_vhost_name)

  ::apache::vhost {"${annex_vhost_name}_ssl":
    servername           => $annex_vhost_name,
    port                 => '443',
    ssl                  => true,
    ssl_protocol         => $annex_vhost_ssl_protocol,
    ssl_honorcipherorder => $annex_vhost_ssl_honorcipherorder,
    ssl_cipher           => $annex_vhost_ssl_cipher,
    ssl_cert             => $cert_paths['cert'],
    ssl_chain            => $cert_paths['chain'],
    ssl_key              => $cert_paths['privkey'],
    headers              => [$annex_vhost_hsts_header],
    docroot              => $annex_vhost_docroot,
    directories          => [{
                             'path'     => $annex_vhost_docroot,
                             'require'  => 'all granted',
                             'options'  => ['Indexes', 'FollowSymLinks', 'MultiViews'],
                              custom_fragment => 'IndexIgnore private provenance-index',
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
                              custom_fragment => 'ReadmeName readme.txt',
                             },
                            ],
    require              => [
      File[$cert_paths['cert']],
      File[$cert_paths['chain']],
      File[$cert_paths['privkey']],
    ],
  }

  File[$cert_paths['cert'], $cert_paths['chain'], $cert_paths['privkey']] ~> Class['Apache::Service']

  file {"${annex_vhost_docroot}/public":
    ensure  => link,
    target  => "../annexroot/public",
    require => File[$annex_vhost_docroot],
  }

  file {$annex_vhost_basic_auth_file:
    ensure  => absent,
  }

  file {$annex_vhost_provenance_basic_auth_file:
    ensure  => present,
    owner   => 'root',
    group   => 'www-data',
    mode    => '0640',
    content => "$annex_vhost_provenance_basic_auth_content",
  }

  $icinga_checks_file = lookup('icinga2::exported_checks::filename')

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
      http_certificate => 25,
    },
    target        => $icinga_checks_file,
    tag           => 'icinga2::exported',
  }
}
