class profile::devel::python {
  $packages = hiera_array('packages::devel::python')

  package { $packages:
    ensure => present,
  }
}
