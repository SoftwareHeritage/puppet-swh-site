# Profile to install development postgresql packages
class profile::devel::postgres {
  $packages = lookup('packages::devel::postgres', Array, 'unique')

  package { $packages:
    ensure => present,
  }
}
