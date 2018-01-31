class profile::swh::deploy::base_vault {
  $conf_directory = hiera('swh::deploy::vault::conf_directory')

  file {$conf_directory:
    ensure => directory,
    owner  => 'root',
    group  => $group,
    mode   => '0755',
  }

  $packages = ['python3-swh.vault']

  package {$packages:
    ensure => 'present',
  }
}
