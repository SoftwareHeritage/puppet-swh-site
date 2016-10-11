# Deployment of the cloud objstorage

class profile::swh::deploy::objstorage_cloud {
  $pinned_packages = [
    'python3-cffi',
    'python3-cryptography',
    'python3-pkg-resources',
    'python3-pyasn1',
    'python3-setuptools',
  ]

  $objstorage_packages = ['python3-swh.objstorage.cloud']

  ::apt::pin {'objstorage_cloud':
    explanation => 'Pin python3-azure-storage dependencies to backports',
    codename    => 'jessie-backports',
    packages    => $pinned_packages,
    priority    => 990,
  } -> package {$objstorage_packages:
    ensure => installed,
  }
}
