# Deployment for swh-loader-mercurial (disk)
class profile::swh::deploy::worker::loader_mercurial {
  $private_tmp = lookup('swh::deploy::worker::loader_mercurial::private_tmp')
  $packages = ['python3-swh.loader.mercurial']

  package {$packages:
    ensure => 'present',
  }

  ::profile::swh::deploy::worker::instance {'loader_mercurial':
    ensure       => 'present',
    private_tmp  => $private_tmp,
    require      => [
      Package[$packages],
    ],
  }
}
