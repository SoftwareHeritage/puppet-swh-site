# Deployment for swh-loader-deposit
class profile::swh::deploy::worker::loader_deposit {
  $concurrency = lookup('swh::deploy::worker::loader_deposit::concurrency')
  $loglevel = lookup('swh::deploy::worker::loader_deposit::loglevel')

  $config_file = lookup('swh::deploy::worker::loader_deposit::config_file')
  $config = lookup('swh::deploy::worker::loader_deposit::config')

  $packages = ['python3-swh.deposit.loader']
  $private_tmp = lookup('swh::deploy::worker::loader_deposit::private_tmp')

  $service_name = 'loader_deposit'

  package {$packages:
    ensure => 'latest',
    notify => Service["swh-worker@$service_name"],
  }

  # This installs the swh-worker@$service_name service
  ::profile::swh::deploy::worker::instance {$service_name:
    ensure       => running,
    concurrency  => $concurrency,
    loglevel     => $loglevel,
    private_tmp  => $private_tmp,
    require      => [
      Package[$packages],
      File[$config_file],
    ],
  }

  file {$config_file:
    ensure  => 'present',
    owner   => 'swhworker',
    group   => 'swhdev',
    mode    => '0640',
    content => inline_template("<%= @config.to_yaml %>\n"),
  }

}
