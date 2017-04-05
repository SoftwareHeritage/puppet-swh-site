# Configure APT for puppet backported packages

class profile::puppet::apt_config {
  if $::lsbdistcodename == 'jessie' {
    $pinned_packages = [
      'facter',
      'hiera',
      'puppet',
      'puppet-common',
      'puppetmaster',
      'puppetmaster-common',
      'puppetmaster-passenger',
      'ruby-deep-merge',
    ]

    ::apt::pin {'puppet':
      explanation => 'Pin puppet dependencies to backports',
      codename    => 'jessie-backports',
      packages    => $pinned_packages,
      priority    => 990,
    }
  }
}
