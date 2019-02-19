# Deployment for swh-lister-pypi
class profile::swh::deploy::worker::swh_lister_pypi {
  $concurrency = lookup('swh::deploy::worker::swh_lister_pypi::concurrency')
  $loglevel = lookup('swh::deploy::worker::swh_lister_pypi::loglevel')

  $config_file = lookup('swh::deploy::worker::swh_lister_pypi::config_file')
  $config = lookup('swh::deploy::worker::swh_lister_pypi::config', Hash, 'deep')

  include ::profile::swh::deploy::base_lister

  ::profile::swh::deploy::worker::instance {'lister_pypi':
    ensure       => present,
    concurrency  => $concurrency,
    loglevel     => $loglevel,
    require      => [
      Package['python3-swh.lister'],
      File[$config_file],
    ],
  }

  # Contains passwords
  file {$config_file:
    ensure  => 'present',
    owner   => 'swhworker',
    group   => 'swhdev',
    mode    => '0640',
    content => inline_template("<%= @config.to_yaml %>\n"),
  }
}
