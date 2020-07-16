# Simple apache domain rewriting
class profile::apache::rewrite_domains {
  include ::profile::apache::common

  $ssl_protocol = lookup('apache::ssl_protocol')
  $ssl_honorcipherorder = lookup('apache::ssl_honorcipherorder')
  $ssl_cipher = lookup('apache::ssl_cipher')
  $hsts_header = lookup('apache::hsts_header')

  $rewrite_domains = lookup('apache::rewrite_domains', Hash, 'deep')
  each($rewrite_domains) |$name, $data| {


    ::profile::letsencrypt::certificate {$name:}
    $cert_paths = ::profile::letsencrypt::certificate_paths($name)

    ::apache::vhost {"${name}_non-ssl":
      servername      => $name,
      port            => '80',
      docroot         => '/var/www',
      redirect_status => 'permanent',
      redirect_dest   => "https://${name}/",
    }


    ::apache::vhost {"${name}_ssl":
      servername           => $name,
      port                 => '443',
      ssl                  => true,
      ssl_protocol         => $ssl_protocol,
      ssl_honorcipherorder => $ssl_honorcipherorder,
      ssl_cipher           => $ssl_cipher,
      ssl_cert             => $cert_paths['cert'],
      ssl_chain            => $cert_paths['chain'],
      ssl_key              => $cert_paths['privkey'],
      headers              => [$hsts_header],
      docroot              => '/var/www',
      rewrites             => [
        { rewrite_rule => $data['rewrites'], },
      ],
    }
  }
}
