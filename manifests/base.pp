class profile::base {
  class { '::ntp':
    servers => hiera('ntp::servers'),
  }

  class { '::locales':
    default_locale => hiera('locales::default_locale'),
    locales        => hiera('locales::installed_locales'),
  }

  $packages = union(
    hiera('packages::base_packages'),
    hiera('packages::extra_packages')
  )

  package { $packages:
    ensure => present,
  }
}
