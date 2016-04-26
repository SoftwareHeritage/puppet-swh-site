class profile::devel::postgres {
  $packages = hiera_array('packages::devel::debian')

  package { $packages:
    ensure => present,
  }
}
