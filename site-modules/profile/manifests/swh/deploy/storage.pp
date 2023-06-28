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

  $main_storage_config = case $storage_config['cls'] {
    'pipeline': { $storage_config['steps'][-1] }
    default:    { $storage_config }
  }

  if ($main_storage_config['cls'] in ['local', 'postgresql', 'cassandra']
      and $main_storage_config['journal_writer']
      and $main_storage_config['journal_writer']['cls'] == 'kafka') {
    include ::profile::swh::deploy::journal
  }

  if $main_storage_config['cls'] == 'cassandra' {
    include ::profile::swh::deploy::storage_cassandra
  }

  if ($storage_config['cls'] == 'pipeline'
      and $storage_config['steps'].filter |$x| {$x['cls'] == 'record_references'}) {

    $conf_file = lookup("swh::deploy::storage::conf_file")
    ::profile::cron::d {'swh.storage-create-partitions':
      command  => "SWH_CONFIG_FILENAME=${conf_file} chronic swh storage create-object-reference-partitions \$(date +%Y-%m-%d) \$(date -d '+1 month' +%Y-%m-%d)",
      target   => 'storage',
      user     => 'swhstorage',
      minute   => 'fqdn_rand',
      hour     => 'fqdn_rand',
      weekday  => 'fqdn_rand',
      monthday => '*',
      month    => '*',
    }
  }
}
