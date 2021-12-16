# Deployment for swh-loader-cvs
class profile::swh::deploy::worker::loader_cvs {
  $private_tmp = lookup('swh::deploy::worker::loader_cvs::private_tmp')

  $packages = ['python3-swh.loader.cvs']

  package {$packages:
    ensure => 'present',
  }

  ::profile::swh::deploy::worker::instance {'loader_cvs':
    ensure      => present,
    private_tmp => $private_tmp,
    require     => [
      Package[$packages],
    ],
  }
}
