# Deployment for swh-loader-debian
class profile::swh::deploy::worker::loader_debian {
  $concurrency = lookup('swh::deploy::worker::loader_debian::concurrency')
  $loglevel = lookup('swh::deploy::worker::loader_debian::loglevel')

  $config_file = lookup('swh::deploy::worker::loader_debian::config_file')
  $config = lookup('swh::deploy::worker::loader_debian::config')

  $packages = ['python3-swh.loader.debian']

  package {$packages:
    ensure => 'present',
  }

  ::profile::swh::deploy::worker::instance {'loader_debian':
    ensure       => present,
    concurrency  => $concurrency,
    loglevel     => $loglevel,
    require      => [
      Package[$packages],
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
