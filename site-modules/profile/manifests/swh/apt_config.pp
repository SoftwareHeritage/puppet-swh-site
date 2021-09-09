# Base class for Software Heritage-specific apt configuration

class profile::swh::apt_config {
  $debian_mirror = lookup('swh::apt_config::debian_mirror')
  $debian_security_mirror = lookup('swh::apt_config::debian_security_mirror')
  $debian_enable_non_free = lookup('swh::apt_config::enable_non_free')

  class {'::apt':
    purge => {
      'sources.list'   => true,
      'sources.list.d' => false,
      'preferences'    => true,
      'preferences.d'  => true,
    },
  }

  package {'apt-transport-https':
    ensure => 'present',
  }

  if lookup('swh::apt_config::unattended_upgrades') {
    include profile::swh::apt_config::unattended_upgrades
  }

  $repos = $debian_enable_non_free ? {
    true    => 'main contrib non-free',
    default => 'main',
  }

  include profile::swh::apt_config::backports

  ::apt::source {'debian':
    location => $debian_mirror,
    release  => $::lsbdistcodename,
    repos    => $repos,
  }

  if $::lsbdistcodename != 'sid' {
    ::apt::source {'debian-updates':
      location => $debian_mirror,
      release  => "${::lsbdistcodename}-updates",
      repos    => $repos,
    }

    if versioncmp($::lsbmajdistrelease, '11') >= 0 {
        $security_release = "${::lsbdistcodename}-security"
    } else {
        $security_release = "${::lsbdistcodename}/updates"
    }

    ::apt::source {'debian-security':
      location => $debian_security_mirror,
      release  => $security_release,
      repos    => $repos,
    }

  } else {
    ::apt::source {['debian-updates', 'debian-security']:
      ensure => absent,
    }
  }

  $swh_repository = lookup('swh::apt_config::swh_repository')
  $swh_release = $::lsbdistcodename ? {
    'bullseye' => 'sid',
    default    => "${::lsbdistcodename}-swh",
  }

  ::apt::source {'softwareheritage':
    comment        => 'Software Heritage specific package repository',
    location       => $swh_repository,
    release        => $swh_release,
    repos          => 'main',
    allow_unsigned => true,
  }

  Package['apt-transport-https'] -> Class['apt']
  Package['apt-transport-https'] -> Class['apt::update'] -> Package <| title != 'apt-transport-https' |>
}
