class profile::swh::deploy::worker::base_vault {
  $packages = ['python3-swh.vault']

  package {$packages:
    ensure => 'present',
  }
}
