# profile for the workstation of a Software Heritage developer
class profile::devel {
  $packages = lookup('packages::devel', Array, 'unique')

  package { $packages:
    ensure => present,
  }

  include ::profile::devel::debian
  include ::profile::devel::postgres
  include ::profile::devel::python
  include ::profile::devel::broker
}
