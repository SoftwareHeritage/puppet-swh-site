# Deployment for swh-loader-deposit
class profile::swh::deploy::worker::loader_deposit {
  $packages = ['python3-swh.deposit.loader']
  $private_tmp = lookup('swh::deploy::worker::loader_deposit::private_tmp')

  package {$packages:
    ensure => 'present',
  }

  # This installs the swh-worker@$service_name service
  ::profile::swh::deploy::worker::instance {'loader_deposit':
    ensure       => 'present',
    private_tmp  => $private_tmp,
    require      => [
      Package[$packages],
    ],
  }
}
