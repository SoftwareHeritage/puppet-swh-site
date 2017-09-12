# Base class for Software Heritage-specific apt configuration

class profile::swh::apt_config {
  $debian_mirror = hiera('swh::apt_config::debian_mirror')
  $debian_security_mirror = hiera('swh::apt_config::debian_security_mirror')

  class {'::apt':
    purge => {
      'sources.list'   => true,
      'sources.list.d' => false,
      'preferences'    => true,
      'preferences.d'  => true,
    },
  }

  if hiera('swh::apt_config::unattended_upgrades') {
    include profile::swh::apt_config::unattended_upgrades
  }

  ::apt::source {'debian':
    location => $debian_mirror,
    release  => $::lsbdistcodename,
    repos    => 'main',
  }

  ::apt::source {'debian-updates':
    location => $debian_mirror,
    release  => "${::lsbdistcodename}-updates",
    repos    => 'main',
  }

  ::apt::source {'debian-security':
    location => $debian_security_mirror,
    release  => "${::lsbdistcodename}/updates",
    repos    => 'main',
  }

  if $::lsbdistcodename == 'jessie' {
    class {'::apt::backports':
      pin      => 100,
      location => $debian_mirror,
      repos    => 'main',
    }
  }

  $swh_repository = hiera('swh::apt_config::swh_repository')
  $swh_release = $::lsbdistcodename ? {
    'buster'  => 'sid',
    'stretch' => 'stretch-swh',
    default   => $::lsbdistcodename,
  }

  ::apt::source {'softwareheritage':
    comment        => 'Software Heritage specific package repository',
    location       => $swh_repository,
    release        => $swh_release,
    repos          => 'main',
    allow_unsigned => true,
  }

  Class['apt::update'] -> Package <||>
}
