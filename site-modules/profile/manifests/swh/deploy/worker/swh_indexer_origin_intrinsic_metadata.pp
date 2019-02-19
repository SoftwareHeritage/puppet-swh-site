# Deployment for swh-indexer-origin-intrinsic-metadata

class profile::swh::deploy::worker::swh_indexer_origin_intrinsic_metadata {
  include ::profile::swh::deploy::indexer

  $concurrency = lookup('swh::deploy::worker::swh_indexer::origin_intrinsic_metadata::concurrency')
  $loglevel = lookup('swh::deploy::worker::swh_indexer::origin_intrinsic_metadata::loglevel')

  $config_file = lookup('swh::deploy::worker::swh_indexer::origin_intrinsic_metadata::config_file')
  $config = lookup('swh::deploy::worker::swh_indexer::origin_intrinsic_metadata::config')

  Package[$::profile::swh::deploy::base_indexer::packages] ~> ::profile::swh::deploy::worker::instance {'indexer_origin_intrinsic_metadata':
    ensure       => present,
    concurrency  => $concurrency,
    loglevel     => $loglevel,
    require      => [
      Class['profile::swh::deploy::indexer'],
      Class['profile::swh::deploy::objstorage_cloud'],
      File[$config_file],
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
