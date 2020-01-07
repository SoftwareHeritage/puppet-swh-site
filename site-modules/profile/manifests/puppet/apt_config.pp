# Apt configuration for puppet
class profile::puppet::apt_config {
  # Backported packages
  if $::lsbdistcodename == 'stretch' {
    $pinned_packages = [
      'facter',
      'libfacter*',
      'libleatherman*',
      'libleatherman-data',
      'libcpp-hocon*',
    ]
  }
  else {
    $pinned_packages = undef
  }

  if $pinned_packages {
    ::apt::pin {'puppet':
      explanation => 'Pin puppet dependencies to backports',
      codename    => "${::lsbdistcodename}-backports",
      packages    => $pinned_packages,
      priority    => 990,
    }
  } else {
    ::apt::pin {'puppet':
      ensure => 'absent',
    }
  }
}
