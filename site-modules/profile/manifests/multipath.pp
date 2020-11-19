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

  systemd::dropin_file {'zfs-import-cache.service.d/multipath.conf':
    ensure   => 'present',
    unit     => 'zfs-import-cache.service',
    filename => 'multipath.conf',
    content  => "# Managed by puppet (module profile::multipath)\n# Set up zfs after multipath\n[Unit]\nAfter=multipathd.socket\n",
  }
}
