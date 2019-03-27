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

  package {$swh_packages:
    ensure  => present,
    require => Apt::Source['softwareheritage'],
  }
}
