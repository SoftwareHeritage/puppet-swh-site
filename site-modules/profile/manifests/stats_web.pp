# Deployment of web-facing stats export (from munin)
class profile::stats_web {
  $vhost_name = lookup('stats_export::vhost::name')
  $vhost_docroot = lookup('stats_export::vhost::docroot')
  $vhost_ssl_protocol = lookup('stats_export::vhost::ssl_protocol')
  $vhost_ssl_honorcipherorder = lookup('stats_export::vhost::ssl_honorcipherorder')
  $vhost_ssl_cipher = lookup('stats_export::vhost::ssl_cipher')
  $vhost_hsts_header = lookup('stats_export::vhost::hsts_header')

  file {$vhost_docroot:
    ensure  => directory,
    owner   => 'www-data',
    group   => 'www-data',
    mode    => '0755',
  }

  include ::profile::apache::common
  include ::profile::ssl

  ::apache::vhost {"${vhost_name}_non-ssl":
    servername      => $vhost_name,
    port            => '80',
    docroot         => $vhost_docroot,
    redirect_status => 'permanent',
    redirect_dest   => "https://${vhost_name}/",
  }

  $ssl_cert_name = 'stats_export_softwareheritage_org'
  $ssl_cert = $::profile::ssl::certificate_paths[$ssl_cert_name]
  $ssl_chain   = $::profile::ssl::chain_paths[$ssl_cert_name]
  $ssl_key  = $::profile::ssl::private_key_paths[$ssl_cert_name]

  ::apache::vhost {"${vhost_name}_ssl":
    servername           => $vhost_name,
    port                 => '443',
    ssl                  => true,
    ssl_protocol         => $vhost_ssl_protocol,
    ssl_honorcipherorder => $vhost_ssl_honorcipherorder,
    ssl_cipher           => $vhost_ssl_cipher,
    ssl_cert             => $ssl_cert,
    ssl_chain            => $ssl_chain,
    ssl_key              => $ssl_key,
    headers              => [$vhost_hsts_header],
    docroot              => $vhost_docroot,
    require              => [
        File[$ssl_cert],
        File[$ssl_chain],
        File[$ssl_key],
     ],
  }
}
