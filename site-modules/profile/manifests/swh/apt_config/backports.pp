# Configure apt pinning for packages we always want from backports
class profile::swh::apt_config::backports {
  $backported_packages = lookup({
    name       => 'swh::apt_config::backported_packages',
    value_type => Hash,
    merge      => {
      strategy        => 'deep',
      knockout_prefix => '-',
    },
  })

  $pinned_packages = $backported_packages[$::facts['os']['distro']['codename']]
  if $pinned_packages {
    ::apt::pin {'swh-backported-packages':
      explanation => 'Pin packages backports',
      codename    => "${::facts['os']['distro']['codename']}-backports",
      packages    => $pinned_packages,
      priority    => 990,
    }
  } else {
    ::apt::pin {'swh-backported-packages':
      ensure => absent,
    }
  }

  if $::facts['os']['distro']['codename'] != 'sid' {
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
