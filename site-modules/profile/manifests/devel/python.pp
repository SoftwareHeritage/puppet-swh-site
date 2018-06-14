class profile::devel::python {
  $packages = lookup('packages::devel::python', Array, 'unique')

  package { $packages:
    ensure => present,
  }
}
