class profile::swh::deploy::base_storage {
  $swh_conf_storage_directory = hiera('swh::deploy::storage::conf_directory')

  file {$swh_conf_storage_directory:
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

}
