# Deployment for swh-loader-mercurial (disk)
class profile::swh::deploy::worker::loader_mercurial {
  include ::profile::swh::deploy::base_loader_git

  $concurrency = lookup('swh::deploy::worker::loader_mercurial::concurrency')
  $loglevel = lookup('swh::deploy::worker::loader_mercurial::loglevel')

  $config_file = lookup('swh::deploy::worker::loader_mercurial::config_file')
  $config = lookup('swh::deploy::worker::loader_mercurial::config')

  $service_name = 'loader_mercurial'
  $private_tmp = lookup('swh::deploy::worker::loader_mercurial::private_tmp')

  $packages = ['python3-swh.loader.mercurial']

  package {$packages:
    ensure => 'latest',
    notify => Service["swh-worker@$service_name"]
  }

  ::profile::swh::deploy::worker::instance {$service_name:
    ensure       => running,
    concurrency  => $concurrency,
    loglevel     => $loglevel,
    private_tmp  => $private_tmp,
    require      => [
      File[$config_file],
    ],
  }

  file {$config_file:
    ensure  => 'present',
    owner   => 'swhworker',
    group   => 'swhworker',
    mode    => '0644',
    content => inline_template("<%= @config.to_yaml %>\n"),
  }
}
