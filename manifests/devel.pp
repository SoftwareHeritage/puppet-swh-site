# profile for the workstation of a Software Heritage developer
class profile::devel {
  $packages = hiera_array('packages::devel')

  package { $packages:
    ensure => present,
  }

  include ::profile::devel::postgres
  include ::profile::devel::python
}
