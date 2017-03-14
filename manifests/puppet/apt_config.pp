# Configure APT for puppet backported packages

class profile::puppet::apt_config {
  if $::lsbdistcodename == 'jessie' {
    $pinned_packages = [
      'puppet',
      'puppet-common',
      'puppetmaster-passenger',
      'puppetmaster-common',
      'puppetmaster',
    ]

    ::apt::pin {'puppet':
      explanation => 'Pin puppet dependencies to backports',
      codename    => 'jessie-backports',
      packages    => $pinned_packages,
      priority    => 990,
    }
  }
}
