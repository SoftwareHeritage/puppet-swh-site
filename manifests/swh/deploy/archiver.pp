# Archiver base configuration

class profile::swh::deploy::archiver {
  include ::profile::swh::deploy::objstorage_cloud

  $config_dir = hiera('swh::deploy::worker::swh_storage_archiver::conf_directory')

  file {$config_dir:
    ensure => 'directory',
    owner  => 'swhworker',
    group  => 'swhworker',
    mode   => '0644',
  }

  $packages = ['python3-swh.storage.archiver']

  package {$packages:
    ensure => 'installed',
  }

}
