# deployment for the lister package
class profile::swh::deploy::base_lister {
  $config_dir = '/etc/softwareheritage/lister'

  # Contains passwords
  file {$config_dir:
    ensure  => 'directory',
    owner   => 'swhworker',
    group   => 'swhdev',
    mode    => '0644',
    purge   => true,
    recurse => true,
  }

  $packages = ['python3-swh.lister']

  package {$packages:
    ensure => 'installed',
  }

  if $::lsbdistcodename == 'jessie' {
    $pinned_packages = [
      'python3-sqlalchemy',
    ]

    ::apt::pin {'swh-lister-base':
      explanation => 'Pin swh.lister dependencies to backports',
      codename    => 'jessie-backports',
      packages    => $pinned_packages,
      priority    => 990,
    } -> Package[$packages]
  }
}
