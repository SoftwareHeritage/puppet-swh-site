# Base Journal configuration

class profile::swh::deploy::journal {
  $conf_directory = '/etc/softwareheritage/journal'
  file {$config_dir:
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
