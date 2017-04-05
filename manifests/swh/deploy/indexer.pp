# Base class for the indexer manifests
class profile::swh::deploy::indexer {

  include ::profile::swh::deploy::objstorage_cloud

  $config_directory = '/etc/softwareheritage/indexer'
  $config_file = "${config_directory}/base.yml"
  $config = hiera('swh::deploy::worker::swh_indexer::base::config')

  $objstorage_config = hiera('swh::azure_objstorage::config')
  $merged_config = merge($config, {'objstorage' => $objstorage_config})

  $packages = ['python3-swh.indexer']

  file {$config_directory:
    ensure => 'directory',
    owner  => 'swhworker',
    group  => 'swhworker',
    mode   => '0755',
  }

  file {$config_file:
    ensure  => 'present',
    owner   => 'swhworker',
    group   => 'swhdev',
    # Contains passwords
    mode    => '0640',
    content => inline_template("<%= @merged_config.to_yaml %>\n"),
  }

  package {$packages:
    ensure => 'latest',
  }
}
