# Deployment for swh-lister-github
class profile::swh::deploy::worker::lister_github {
  $concurrency = lookup('swh::deploy::worker::lister_github::concurrency')
  $loglevel = lookup('swh::deploy::worker::lister_github::loglevel')

  $config_file = lookup('swh::deploy::worker::lister_github::config_file')
  $config = lookup('swh::deploy::worker::lister_github::config', Hash, 'deep')

  include ::profile::swh::deploy::base_lister

  ::profile::swh::deploy::worker::instance {'lister_github':
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
