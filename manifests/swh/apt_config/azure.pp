# azure-specific apt configuration

class profile::swh::apt_config::azure {
  $azure_repository = hiera('swh::apt_config::azure_repository')
  ::apt::source {'azure':
    comment  => 'Azure specific package repository',
    location => $azure_repository,
    release  => $::lsbdistcodename,
    repos    => 'main',
  }

  # XXX: dependency loop between this package and the previous apt source...
  package {'debian-azure-archive-keyring':
    ensure => installed,
  }
}
