# Deployment for swh-indexer-mimetype

class profile::swh::deploy::worker::indexer_mimetype {
  include ::profile::swh::deploy::indexer

  $concurrency = lookup('swh::deploy::worker::indexer::mimetype::concurrency')
  $loglevel = lookup('swh::deploy::worker::indexer::mimetype::loglevel')

  $config_file = lookup('swh::deploy::worker::indexer::mimetype::config_file')
  $config = lookup('swh::deploy::worker::indexer::mimetype::config')

  Package[$::profile::swh::deploy::base_indexer::packages] ~> ::profile::swh::deploy::worker::instance {'indexer_content_mimetype':
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
