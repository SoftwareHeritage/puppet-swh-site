# Base Journal configuration

class profile::swh::deploy::journal {
  $conf_directory = lookup('swh::deploy::journal::conf_directory')

  file {$conf_directory:
    ensure => 'directory',
    owner  => 'swhworker',
    group  => 'swhworker',
    mode   => '0644',
  }

  $swh_packages = ['python3-swh.journal']

  $task_backported_packages = lookup('swh::deploy::journal::backported_packages')
  $pinned_packages = $task_backported_packages[$::lsbdistcodename]
  if $pinned_packages {
    ::apt::pin {'swh-journal':
      explanation => 'Pin swh.journal dependencies to backports',
      codename    => "${::lsbdistcodename}-backports",
      packages    => $pinned_packages,
      priority    => 990,
    }
    -> package {$swh_packages:
      ensure  => present,
      require => Apt::Source['softwareheritage'],
    }
  } else {
    package {$swh_packages:
      ensure  => present,
      require => Apt::Source['softwareheritage'],
    }
  }
}
