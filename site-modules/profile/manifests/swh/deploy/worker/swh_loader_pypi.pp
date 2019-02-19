# Deployment for swh-loader-pypi
class profile::swh::deploy::worker::loader_pypi {
  $concurrency = lookup('swh::deploy::worker::loader_pypi::concurrency')
  $loglevel = lookup('swh::deploy::worker::loader_pypi::loglevel')

  $config_file = lookup('swh::deploy::worker::loader_pypi::config_file')
  $config = lookup('swh::deploy::worker::loader_pypi::config')

  $private_tmp = lookup('swh::deploy::worker::loader_pypi::private_tmp')

  $packages = ['python3-swh.loader.pypi']

  package {$packages:
    ensure => 'latest',
  }

  ::profile::swh::deploy::worker::instance {'loader_pypi':
    ensure       => present,
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
    group   => 'swhworker',
    mode    => '0644',
    content => inline_template("<%= @config.to_yaml %>\n"),
  }
}
