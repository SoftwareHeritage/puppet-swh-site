# apt configuration for Let's Encrypt

class profile::letsencrypt::apt_config {
  $pinned_packages = ['certbot'] + prefix([
      'acme', 'asn1crypto', 'certbot', 'certbot-*', 'cryptography', 'idna',
      'josepy', 'parsedatetime', 'pbr',
  ], 'python3-')

  if $::facts['os']['distro']['codename'] == 'stretch' {
    ::apt::pin {'letsencrypt-backports':
      explanation => 'Pin letsencrypt backports',
      codename    => "${::facts['os']['distro']['codename']}-backports",
      packages    => $pinned_packages,
      priority    => 990,
    }
  } else {
    ::apt::pin {'letsencrypt-backports':
      ensure => absent,
    }
  }
}
