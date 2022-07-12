# Thanos query
class profile::thanos::query {
  include profile::thanos::base

  $service_name = 'thanos-query'
  $unit_name = "${service_name}.service"

  $port_http = lookup('thanos::query::port_http')
  $non_puppet_managed_stores = lookup('thanos::query::non_puppet_managed::stores')

  $internal_ip = ip_for_network(lookup('internal_network'))
  $config_filepath = lookup('thanos::query::config_filepath')

  concat::fragment { 'header':
    target  => $config_filepath,
    content => "---\n- targets:\n",
    order   => 0,
    tag     => 'thanos',
    require => File[$config_dir],
  }

  $non_puppet_managed_stores.map | $store | {
    concat::fragment { $store:
      target  => $config_filepath,
      content => "  - ${store}\n",
      order   => 1,
      tag     => 'thanos',
      require => File[$config_dir],
    }
  }

  # Deal with collected resources
  Concat <<| tag == 'thanos' |>> ~> Service[$service_name]
  Concat::Fragment <<| tag == 'thanos' |>> ~> Service[$service_name]

  $query_arguments = {
    "http-address"   => "${internal_ip}:${port_http}",
    "store.sd-files" => $config_filepath,
  }

  systemd::unit_file {$unit_name:
    ensure  => present,
    content => template("profile/thanos/${unit_name}.erb"),
    require => Class['profile::thanos::base'],
    notify  => Service[$service_name],
  }

  # Template uses:
  # $query_arguments
  service {$service_name:
    ensure  => 'running',
    enable  => true,
  }

  Class['profile::thanos::base'] ~> Service[$service_name]
}
