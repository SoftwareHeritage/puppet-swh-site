class profile::devel::postgres {
  $packages = hiera_array('packages::devel::postgres')

  package { $packages:
    ensure => present,
  }
}
