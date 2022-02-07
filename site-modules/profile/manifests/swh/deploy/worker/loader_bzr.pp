# Deployment for swh-loader-bzr
class profile::swh::deploy::worker::loader_bzr {
  include ::profile::swh::deploy::loader

  $packages = ['python3-swh.loader.bzr']
  $private_tmp = lookup('swh::deploy::worker::loader_bzr::private_tmp')

  package {$packages:
    ensure => 'present',
  }

  ::profile::swh::deploy::worker::instance {'loader_bzr':
    ensure      => 'present',
    private_tmp => $private_tmp,
    require     => [
      Package[$packages],
    ],
  }
}
