# Deployment of the ceph objstorage

class profile::swh::deploy::objstorage_ceph {
  include profile::ceph::base

  $objstorage_packages = ['python3-swh.objstorage.rados']

  package {$objstorage_packages:
    ensure => installed,
  }

  $objstorage_config = lookup('swh::deploy::objstorage::ceph::config')

  file {"${profile::swh::deploy::objstorage::conf_directory}/ceph.yml":
    ensure  => present,
    owner   => 'root',
    group   => $profile::swh::deploy::objstorage::group,
    mode    => '0640',
    content => inline_yaml($objstorage_config),
  }
}
