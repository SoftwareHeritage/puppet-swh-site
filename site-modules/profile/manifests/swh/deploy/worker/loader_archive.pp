# Deployment for loader-archive
class profile::swh::deploy::worker::loader_archive {
  include ::profile::swh::deploy::worker::loader_package

  $private_tmp = lookup('swh::deploy::worker::loader_archive::private_tmp')

  ::profile::swh::deploy::worker::instance {'loader_archive':
    ensure       => present,
    private_tmp  => $private_tmp,
    require      => [
      Package[$packages],
    ],
  }
}
