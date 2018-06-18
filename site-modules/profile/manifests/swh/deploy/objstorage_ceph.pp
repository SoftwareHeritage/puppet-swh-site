# Deployment of the ceph objstorage

class profile::swh::deploy::objstorage_ceph {
  include profile::ceph::base

  $objstorage_packages = ['python3-swh.objstorage.rados']

  package {$objstorage_packages:
    ensure => installed,
  }
}
