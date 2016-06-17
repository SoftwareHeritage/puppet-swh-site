# stats_export master class
class profile::munin::stats_export {
  $vhost_name = hiera('stats_export::vhost::name')
  $vhost_docroot = hiera('stats_export::vhost::docroot')
  $vhost_ssl_protocol = hiera('stats_export::vhost::ssl_protocol')
  $vhost_ssl_honorcipherorder = hiera('stats_export::vhost::ssl_honorcipherorder')
  $vhost_ssl_cipher = hiera('stats_export::vhost::ssl_cipher')
  $vhost_hsts_header = hiera('stats_export::vhost::hsts_header')

  $packages = ['python3-click']

  package {$packages:
    ensure => present,
  }

  file {'/usr/local/bin/export-rrd':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    source  => 'puppet:///modules/profile/munin/stats_export/export-rrd',
    require => Package[$packages],
  }

  file {$vhost_docroot:
    ensure  => directory,
    owner   => 'munin',
    group   => 'www-data',
    mode    => '2755',
  }

  include ::profile::ssl
  include ::apache

  ::apache::vhost {"${vhost_name}_non-ssl":
    servername      => $vhost_name,
    port            => '80',
    docroot         => $vhost_docroot,
    redirect_status => 'permanent',
    redirect_dest   => "https://${vhost_name}/",
  }

  $ssl_cert_name = 'star_softwareheritage_org'
  $ssl_cert = $::profile::ssl::certificate_paths[$ssl_cert_name]
  $ssl_ca   = $::profile::ssl::ca_paths[$ssl_cert_name]
  $ssl_key  = $::profile::ssl::private_key_paths[$ssl_cert_name]

  ::apache::vhost {"${vhost_name}_ssl":
    servername           => $vhost_name,
    port                 => '443',
    ssl                  => true,
    ssl_protocol         => $vhost_ssl_protocol,
    ssl_honorcipherorder => $vhost_ssl_honorcipherorder,
    ssl_cipher           => $vhost_ssl_cipher,
    ssl_cert             => $ssl_cert,
    ssl_ca               => $ssl_ca,
    ssl_key              => $ssl_key,
    headers              => [$vhost_hsts_header],
    docroot              => $vhost_docroot,
    require              => [
        File[$ssl_cert],
        File[$ssl_ca],
        File[$ssl_key],
    ],
  }

}
