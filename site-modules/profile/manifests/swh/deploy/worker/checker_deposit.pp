# Deployment for deposit's archive checker
class profile::swh::deploy::worker::checker_deposit {
  include ::profile::swh::deploy::worker::checker_deposit

  $private_tmp = lookup('swh::deploy::worker::checker_deposit::private_tmp')
  ::profile::swh::deploy::worker::instance {'checker_deposit':
    ensure       => 'present',
    private_tmp  => $private_tmp,
  }
}
