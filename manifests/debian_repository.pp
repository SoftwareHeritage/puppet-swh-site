# Debian repository configuration

class profile::debian_repository {
  $packages = ['reprepro']

  package {$packages:
    ensure => installed,
  }

  $repository_basepath =  hiera('debian_repository::basepath')

  $repository_vhost_name = hiera('debian_repository::vhost::name')
  $repository_vhost_aliases = hiera('debian_repository::vhost::aliases')
  $repository_vhost_docroot = hiera('debian_repository::vhost::docroot')
  $repository_vhost_docroot_owner = hiera('debian_repository::vhost::docroot_owner')
  $repository_vhost_docroot_group = hiera('debian_repository::vhost::docroot_group')
  $repository_vhost_docroot_mode = hiera('debian_repository::vhost::docroot_mode')
  $repository_vhost_ssl_protocol = hiera('debian_repository::vhost::ssl_protocol')
  $repository_vhost_ssl_honorcipherorder = hiera('debian_repository::vhost::ssl_honorcipherorder')
  $repository_vhost_ssl_cipher = hiera('debian_repository::vhost::ssl_cipher')
  $repository_vhost_hsts_header = hiera('debian_repository::vhost::hsts_header')

  include ::profile::ssl
  include ::profile::apache::common

  ::apache::vhost {"${repository_vhost_name}_non-ssl":
    servername      => $repository_vhost_name,
    serveraliases   => $repository_vhost_aliases,
    port            => '80',
    docroot         => $repository_vhost_docroot,
    manage_docroot  => false,  # will be managed by the SSL resource
    redirect_status => 'permanent',
    redirect_dest   => "https://${repository_vhost_name}/",
  }

  $ssl_cert_name = 'star_softwareheritage_org'
  $ssl_cert = $::profile::ssl::certificate_paths[$ssl_cert_name]
  $ssl_chain   = $::profile::ssl::chain_paths[$ssl_cert_name]
  $ssl_key  = $::profile::ssl::private_key_paths[$ssl_cert_name]

  ::apache::vhost {"${repository_vhost_name}_ssl":
    servername           => $repository_vhost_name,
    port                 => '443',
    ssl                  => true,
    ssl_protocol         => $repository_vhost_ssl_protocol,
    ssl_honorcipherorder => $repository_vhost_ssl_honorcipherorder,
    ssl_cipher           => $repository_vhost_ssl_cipher,
    ssl_cert             => $ssl_cert,
    ssl_chain            => $ssl_chain,
    ssl_key              => $ssl_key,
    headers              => [$repository_vhost_hsts_header],
    docroot              => $repository_vhost_docroot,
    docroot_owner        => $repository_vhost_docroot_owner,
    docroot_group        => $repository_vhost_docroot_group,
    docroot_mode         => $repository_vhost_docroot_mode,
    directories          => [
      {
        path    => $repository_vhost_docroot,
        require => 'all granted',
        options => ['Indexes', 'FollowSymLinks', 'MultiViews'],
      },
    ],
    require              => [
        File[$ssl_cert],
        File[$ssl_chain],
        File[$ssl_key],
    ],
  }

  $icinga_checks_file = '/etc/icinga2/conf.d/exported-checks.conf'

  @@::icinga2::object::service {"debian repository http redirect on ${::fqdn}":
    service_name  => 'debian repository http redirect',
    import        => ['generic-service'],
    host_name     => $::fqdn,
    check_command => 'http',
    vars          => {
      http_address => $repository_vhost_name,
      http_vhost   => $repository_vhost_name,
      http_uri     => '/',
    },
    target        => $icinga_checks_file,
    tag           => 'icinga2::exported',
  }

  @@::icinga2::object::service {"debian repository https on ${::fqdn}":
    service_name  => 'debian repository https',
    import        => ['generic-service'],
    host_name     => $::fqdn,
    check_command => 'http',
    vars          => {
      http_address    => $repository_vhost_name,
      http_vhost      => $repository_vhost_name,
      http_ssl        => true,
      http_sni        => true,
      http_uri        => '/',
      http_onredirect => sticky
    },
    target        => $icinga_checks_file,
    tag           => 'icinga2::exported',
  }

  @@::icinga2::object::service {"debian repository https certificate ${::fqdn}":
    service_name  => 'debian repository https certificate',
    import        => ['generic-service'],
    host_name     => $::fqdn,
    check_command => 'http',
    vars          => {
      http_address     => $repository_vhost_name,
      http_vhost       => $repository_vhost_name,
      http_ssl         => true,
      http_sni         => true,
      http_certificate => 60,
    },
    target        => $icinga_checks_file,
    tag           => 'icinga2::exported',
  }
}
