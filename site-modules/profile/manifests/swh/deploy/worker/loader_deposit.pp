# Deployment for deposit's loader
class profile::swh::deploy::worker::loader_deposit {
  $private_tmp = lookup('swh::deploy::worker::loader_deposit::private_tmp')
  ::profile::swh::deploy::worker::instance {'loader_deposit':
    ensure       => 'present',
    private_tmp  => $private_tmp,
  }
}
