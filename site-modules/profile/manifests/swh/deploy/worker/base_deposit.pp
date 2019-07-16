class profile::swh::deploy::worker::base_deposit {
  $packages = ['python3-swh.deposit.loader']

  package {$packages:
    ensure => 'present',
  }
}
