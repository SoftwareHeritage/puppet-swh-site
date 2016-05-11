class profile::devel::broker {
  $packages = hiera_array('packages::devel::broker')

  package { $packages:
    ensure => present,
  }
}
