class profile::swh::deploy::base_vault {
  $packages = ['python3-swh.vault']

  package {$packages:
    ensure => 'present',
  }
}
