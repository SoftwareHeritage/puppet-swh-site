# Deployment for swh-indexer-language

class profile::swh::deploy::worker::indexer_language {
  include ::profile::swh::deploy::indexer

  $concurrency = lookup('swh::deploy::worker::indexer::language::concurrency')
  $loglevel = lookup('swh::deploy::worker::indexer::language::loglevel')

  $config_file = lookup('swh::deploy::worker::indexer::language::config_file')
  $config = lookup('swh::deploy::worker::indexer::language::config')

  Package[$::profile::swh::deploy::base_indexer::packages] ~> ::profile::swh::deploy::worker::instance {'indexer_content_language':
    ensure       => 'stopped',
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
