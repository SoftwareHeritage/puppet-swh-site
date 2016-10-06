# Loader base configuration

class profile::swh::deploy::loader {
  $config_dir = '/etc/softwareheritage/loader'
  file {$config_dir:
    ensure => 'directory',
    owner  => 'swhworker',
    group  => 'swhworker',
    mode   => '0644',
  }
}
