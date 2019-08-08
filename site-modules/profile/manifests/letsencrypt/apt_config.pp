# apt configuration for Let's Encrypt

class profile::letsencrypt::apt_config {
  $pinned_packages = ['certbot'] + prefix([
      'acme', 'asn1crypto', 'certbot', 'certbot-*', 'cryptography', 'idna',
      'josepy', 'parsedatetime', 'pbr',
  ], 'python3-')

  if $::lsbdistcodename == 'stretch' {
    ::apt::pin {'letsencrypt-backports':
      explanation => 'Pin letsencrypt backports',
      codename    => "${::lsbdistcodename}-backports",
      packages    => $pinned_packages,
      priority    => 990,
    }
  } else {
    ::apt::pin {'letsencrypt-backports':
      ensure => absent,
    }
  }
}
