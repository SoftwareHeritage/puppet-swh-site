# Base Journal configuration

class profile::swh::deploy::journal {
  $conf_directory = lookup('swh::deploy::journal::conf_directory')

  file {$conf_directory:
    ensure => 'directory',
    owner  => 'swhworker',
    group  => 'swhworker',
    mode   => '0644',
  }

  $package_name = 'python3-swh.journal'

  package {$package_name:
    ensure => latest,
  }
}
