class profile::devel::broker {
  $packages = lookup('packages::devel::broker', Array, 'unique')

  package { $packages:
    ensure => present,
  }
}
