# Deployment for swh-indexer-rehash

class profile::swh::deploy::worker::indexer_rehash {
  include ::profile::swh::deploy::indexer

  $concurrency = lookup('swh::deploy::worker::indexer::rehash::concurrency')
  $loglevel = lookup('swh::deploy::worker::indexer::rehash::loglevel')

  $config_file = lookup('swh::deploy::worker::indexer::rehash::config_file')
  $config_directory = lookup('swh::deploy::base_indexer::config_directory')
  $config_path = "${config_directory}/${config_file}"
  $config = lookup('swh::deploy::worker::indexer::rehash::config')

  Package[$::profile::swh::deploy::base_indexer::packages] ~> ::profile::swh::deploy::worker::instance {'indexer_rehash':
    ensure       => 'stopped',
    concurrency  => $concurrency,
    loglevel     => $loglevel,
    require      => [
      Class['profile::swh::deploy::indexer'],
      Class['profile::swh::deploy::objstorage_cloud'],
      File[$config_path],
    ],
  }

  file {$config_path:
    ensure  => 'present',
    owner   => 'swhworker',
    group   => 'swhdev',
    # Contains passwords
    mode    => '0640',
    content => inline_template("<%= @config.to_yaml %>\n"),
  }
}
