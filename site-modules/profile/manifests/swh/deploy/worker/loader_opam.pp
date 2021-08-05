# Deployment for opam loader
class profile::swh::deploy::worker::loader_opam {
  include ::profile::swh::deploy::worker::loader_package
  $private_tmp = lookup('swh::deploy::worker::loader_opam::private_tmp')

  $packages = ['opam']
  package {$packages:
    ensure => 'present',
  }

  ::profile::swh::deploy::worker::instance {'loader_opam':
    ensure      => present,
    private_tmp => $private_tmp,
    sentry_name => 'loader_core',
    require     => [
      Package[$::profile::swh::deploy::loader_package::packages],
      Package[$packages],
    ],
  }
}
