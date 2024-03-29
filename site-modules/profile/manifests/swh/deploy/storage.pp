# Deployment of the swh.storage.api server

class profile::swh::deploy::storage {
  include ::profile::swh::deploy::base_storage

  $package = $::profile::swh::deploy::base_storage::package

  ::profile::swh::deploy::rpc_server {'storage':
    executable        => 'swh.storage.api.server:make_app_from_configfile()',
    worker            => 'sync',
    http_check_string => '<title>Software Heritage storage server</title>',
    subscribe         => Package[$package]
  }

  $storage_config = lookup('swh::deploy::storage::config')['storage']

  if ($storage_config['cls'] == 'local'
      and $storage_config['journal_writer']
      and $storage_config['journal_writer']['cls'] == 'kafka') {
    include ::profile::swh::deploy::journal
  }

  if $storage_config['cls'] == 'cassandra' {
    include ::profile::swh::deploy::storage_cassandra
  }
}
