class profile::devel::debian {
  $packages = lookup('packages::devel::debian', Array, 'unique')

  package { $packages:
    ensure => present,
  }
}
