class profile::devel::debian {
  $packages = hiera_array('packages::devel::debian')

  package { $packages:
    ensure => present,
  }
}
