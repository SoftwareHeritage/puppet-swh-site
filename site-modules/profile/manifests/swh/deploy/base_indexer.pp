# Base class for indexer related manifests
class profile::swh::deploy::base_indexer {
  $config_directory = lookup('swh::deploy::base_indexer::config_directory')

  file {$config_directory:
    ensure => 'directory',
    owner  => 'swhworker',
    group  => 'swhworker',
    mode   => '0755',
  }

  $packages = ['python3-swh.indexer']
  package {$packages:
    ensure => 'latest',
  }
}
