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

  $backported_packages = {
    'stretch' => ['librdkafka1'],
  }

  $pinned_packages = $backported_packages[$::lsbdistcodename]

  if $pinned_packages {
    ::apt::pin {'swh-journal':
      explanation => 'Pin swh.journal dependencies to backports',
      codename    => "${::lsbdistcodename}-backports",
      packages    => $pinned_packages,
      priority    => 990,
    }
    -> package {$swh_packages:
      ensure => installed,
      require => Apt::Source['softwareheritage'],
    }
  } else {
    package {$swh_packages:
      ensure => installed,
      require => Apt::Source['softwareheritage'],
    }
  }
}
