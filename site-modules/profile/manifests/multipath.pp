# Various overrides for multipath setup
class profile::multipath {
  $multipath_packages = ['multipath-tools', 'multipath-tools-boot']

  ::systemd::unit_file {'multipathd.service':
    ensure => 'present',
    source => 'puppet:///modules/profile/multipath/multipathd.service',
  } ->
  package {$multipath_packages:
    ensure => present
  }
  }
}
