class profile::desktop {
  $packages = lookup('packages::desktop', Array, 'unique')

  package { $packages:
    ensure => present,
  }

  include ::profile::desktop::printers
}
