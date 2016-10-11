# Deployment for swh-storage-archiver-azure
class profile::swh::deploy::worker::swh_storage_archiver_azure {
  include ::profile::swh::deploy::archiver

  $concurrency = hiera('swh::deploy::worker::swh_storage_archiver_azure::concurrency')
  $loglevel = hiera('swh::deploy::worker::swh_storage_archiver_azure::loglevel')
  $task_broker = hiera('swh::deploy::worker::swh_storage_archiver_azure::task_broker')

  $config_file = hiera('swh::deploy::worker::swh_storage_archiver_azure::conf_file')
  $config = hiera('swh::deploy::worker::swh_storage_archiver_azure::config')

  $storages_config_list = hiera_array(
    'swh::deploy::worker::swh_storage_archiver::storages')
  $objstorage_azure_config = hiera('swh::azure_objstorage::config')

  $objstorages_config = $storages_config_list + [
    merge({"host" => "azure"}, $objstorage_azure_config)
  ]

  # Create the full configuration
  $merged_config = merge($config, {
    'storages' => $objstorages_config
  })

  $task_modules = ['swh.storage.archiver.tasks']
  $task_queues = ['swh_storage_archiver_worker_to_backend']

  ::profile::swh::deploy::worker::instance {'swh_storage_archiver_azure':
    ensure       => present,
    concurrency  => $concurrency,
    loglevel     => $loglevel,
    task_broker  => $task_broker,
    task_modules => $task_modules,
    task_queues  => $task_queues,
    require      => [
      File[$config_file],
    ],
  }

  file {$config_file:
    ensure  => 'present',
    owner   => 'swhworker',
    group   => 'swhdev',
    # Contains passwords
    mode    => '0640',
    content => inline_template('<%= @merged_config.to_yaml %>'),
  }
}
