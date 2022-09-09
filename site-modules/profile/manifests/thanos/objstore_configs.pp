# Thanos objstore configs
class profile::thanos::objstore_configs {
  include profile::thanos::base

  $stores = lookup('thanos::stores')

  $azure_account = lookup('thanos::objstore::azure_account')
  $azure_account_key = lookup('thanos::objstore::azure_account_key')

  $config_dir = $::profile::thanos::base::config_dir
  $stores.each | $dataset_name, $service | {
    $objstore_config = {
      "type"   => "AZURE",
      "config" => {
        "storage_account"     => $azure_account,
        "storage_account_key" => $azure_account_key,
        "container"           => $service['azure-storage-container'],
      },
    }

    file {"${::profile::thanos::base::config_dir}/objstore-${dataset_name}.yml":
      ensure  => present,
      owner   => 'root',
      group   => 'prometheus',
      mode    => '0640',
      content => inline_yaml($objstore_config),
      require => File[$::profile::thanos::base::config_dir],
    }
    ~> Service <| tag == "thanos-objstore-${dataset_name}" |>
  }
}
