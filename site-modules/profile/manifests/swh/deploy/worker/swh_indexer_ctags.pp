# Deployment for swh-indexer-ctags

class profile::swh::deploy::worker::swh_indexer_ctags {
  include ::profile::swh::deploy::indexer

  $concurrency = lookup('swh::deploy::worker::swh_indexer::ctags::concurrency')
  $loglevel = lookup('swh::deploy::worker::swh_indexer::ctags::loglevel')

  $config_file = lookup('swh::deploy::worker::swh_indexer::ctags::config_file')
  $config = lookup('swh::deploy::worker::swh_indexer::ctags::config')

  $packages = ['universal-ctags']
  package {$packages:
    ensure => 'present',
  }

  Package[$::profile::swh::deploy::base_indexer::packages] ~> ::profile::swh::deploy::worker::instance {'indexer_content_ctags':
    ensure       => 'stopped',
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
