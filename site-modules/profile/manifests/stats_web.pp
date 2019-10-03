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

  ::apache::vhost {"${vhost_name}_non-ssl":
    servername      => $vhost_name,
    port            => '80',
    docroot         => $vhost_docroot,
    redirect_status => 'permanent',
    redirect_dest   => "https://${vhost_name}/",
  }

  $ssl_cert_name = 'stats_export'
  ::profile::letsencrypt::certificate {$ssl_cert_name:}
  $cert_paths = ::profile::letsencrypt::certificate_paths($ssl_cert_name)

  ::apache::vhost {"${vhost_name}_ssl":
    servername           => $vhost_name,
    port                 => '443',
    ssl                  => true,
    ssl_protocol         => $vhost_ssl_protocol,
    ssl_honorcipherorder => $vhost_ssl_honorcipherorder,
    ssl_cipher           => $vhost_ssl_cipher,
    ssl_cert             => $cert_paths['cert'],
    ssl_chain            => $cert_paths['chain'],
    ssl_key              => $cert_paths['privkey'],
    headers              => [$vhost_hsts_header],
    docroot              => $vhost_docroot,
    require              => [
        Profile::Letsencrypt::Certificate[$ssl_cert_name],
        File[$ssl_chain],
        File[$ssl_key],
     ],
  }

  File[$cert_paths['cert'], $cert_paths['chain'], $cert_paths['privkey']] ~> Class['Apache::Service']
}
