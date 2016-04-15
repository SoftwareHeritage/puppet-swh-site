class profile::desktop {
  $packages = hiera_array('packages::desktop')

  package { $packages:
    ensure => present,
  }
}
