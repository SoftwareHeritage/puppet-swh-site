# Base class for the indexer worker manifests
class profile::swh::deploy::indexer {
  include ::profile::swh::deploy::base_indexer
  include ::profile::swh::deploy::objstorage_cloud

  $config_directory = lookup('swh::deploy::base_indexer::config_directory')
  $config_file = "${config_directory}/base.yml"
  $config = lookup('swh::deploy::worker::swh_indexer::base::config')

  file {$config_file:
    ensure  => 'present',
    owner   => 'swhworker',
    group   => 'swhdev',
    # Contains passwords
    mode    => '0640',
    content => inline_template("<%= @config.to_yaml %>\n"),
  }
}
