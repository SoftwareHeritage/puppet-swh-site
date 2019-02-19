# Deployment for swh-lister-gitlab
class profile::swh::deploy::worker::swh_lister_gitlab {
  $concurrency = lookup('swh::deploy::worker::swh_lister_gitlab::concurrency')
  $loglevel = lookup('swh::deploy::worker::swh_lister_gitlab::loglevel')

  $config_file = lookup('swh::deploy::worker::swh_lister_gitlab::config_file')
  $config = lookup('swh::deploy::worker::swh_lister_gitlab::config', Hash, 'deep')

  include ::profile::swh::deploy::base_lister

  ::profile::swh::deploy::worker::instance {'lister_gitlab':
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
