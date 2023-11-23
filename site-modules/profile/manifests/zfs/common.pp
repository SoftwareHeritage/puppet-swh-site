class profile::zfs::common {
  # Allow zpool configuration to be undefined (that allows to bypass the manual
  # configuration on some nodes e.g. storage1.staging)
  $zpool_configuration = lookup('zfs::common::zpool_configuration', {default_value => {}})

  if $zpool_configuration {
    # When provided, let's create the pool of data out of it
    # zpool create -f data /dev/vdb
    zpool { 'data':
      ensure => 'present',
      *      => $zpool_configuration,
    }
  } else {  # Otherwise, do nothing but ensure it's already configured
    zpool { 'data':
      ensure => 'present',
    }
  }
}
