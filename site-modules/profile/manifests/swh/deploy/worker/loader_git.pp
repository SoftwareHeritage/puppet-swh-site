# Deployment for swh-loader-git (remote)
class profile::swh::deploy::worker::loader_git {
  include ::profile::swh::deploy::base_loader_git

  $concurrency = lookup('swh::deploy::worker::loader_git::concurrency')
  $loglevel = lookup('swh::deploy::worker::loader_git::loglevel')

  $config_file = lookup('swh::deploy::worker::loader_git::config_file')
  $config = lookup('swh::deploy::worker::loader_git::config')

  ::profile::swh::deploy::worker::instance {'loader_git':
    ensure       => present,
    concurrency  => $concurrency,
    loglevel     => $loglevel,
    require      => [
      Class['profile::swh::deploy::base_loader_git'],
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
