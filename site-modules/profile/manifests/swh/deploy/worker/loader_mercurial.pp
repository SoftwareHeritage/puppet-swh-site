# Deployment for swh-loader-mercurial (disk)
class profile::swh::deploy::worker::loader_mercurial {
  include ::profile::swh::deploy::base_loader_mercurial
  $private_tmp = lookup('swh::deploy::worker::loader_mercurial::private_tmp')

  ::profile::swh::deploy::worker::instance {'loader_mercurial':
    ensure      => 'present',
    private_tmp => $private_tmp,
    require     => [
      Package[$::profile::swh::deploy::base_loader_mercurial::packages],
    ],
  }
}
