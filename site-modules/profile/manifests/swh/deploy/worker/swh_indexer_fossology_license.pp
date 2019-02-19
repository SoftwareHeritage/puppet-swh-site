# Deployment for swh-indexer-fossology-license

class profile::swh::deploy::worker::indexer_fossology_license {
  include ::profile::swh::deploy::indexer

  $concurrency = lookup('swh::deploy::worker::indexer_fossology_license::concurrency')
  $loglevel = lookup('swh::deploy::worker::indexer_fossology_license::loglevel')

  $config_file = lookup('swh::deploy::worker::indexer_fossology_license::config_file')
  $config = lookup('swh::deploy::worker::indexer_fossology_license::config')

  $packages = ['fossology-nomossa']
  package {$packages:
    ensure => 'present',
  }

  Package[$::profile::swh::deploy::base_indexer::packages] ~> ::profile::swh::deploy::worker::instance {'indexer_fossology_license':
    ensure       => present,
    concurrency  => $concurrency,
    loglevel     => $loglevel,
    require      => [
      Class['profile::swh::deploy::indexer'],
      Class['profile::swh::deploy::objstorage_cloud'],
      File[$config_file],
      Package[$packages],
    ],
  }

  file {$config_file:
    ensure  => 'present',
    owner   => 'swhworker',
    group   => 'swhdev',
    # Contains passwords
    mode    => '0640',
    content => inline_template("<%= @config.to_yaml %>\n"),
  }
}
