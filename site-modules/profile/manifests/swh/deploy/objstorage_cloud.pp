# Deployment of the cloud objstorage
class profile::swh::deploy::objstorage_cloud {
  $objstorage_packages = ['python3-swh.objstorage.cloud']

  package {$objstorage_packages:
    ensure => installed,
  }
}
