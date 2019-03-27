# Configure apt pinning for packages we always want from backports
class profile::swh::apt_config::backports {
  $backported_packages = lookup('swh::apt_config::backported_packages', {
    merge => {
      strategy           => deep,
      sort_merged_arrays => true,
    },
  })
  $pinned_packages = $backported_packages[$::lsbdistcodename]
  if $pinned_packages {
    ::apt::pin {'swh-backported-packages':
      explanation => 'Pin packages backports',
      codename    => "${::lsbdistcodename}-backports",
      packages    => $pinned_packages,
      priority    => 990,
    }
  } else {
    ::apt::pin {'swh-backported-packages':
      ensure => absent,
    }
  }

  if $::lsbdistcodename != 'sid' {
    class {'::apt::backports':
      pin      => 100,
      location => $profile::swh::apt_config::debian_mirror,
      repos    => $profile::swh::apt_config::repos,
    }
  }
  else {
    ::apt::source {['backports', 'debian-updates', 'debian-security']:
      ensure => absent,
    }
  }
}
