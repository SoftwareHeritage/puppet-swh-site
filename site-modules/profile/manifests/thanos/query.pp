# Thanos query
class profile::thanos::query {
  include profile::thanos::base

  $service_name = 'thanos-query'
  $unit_name = "${service_name}.service"

  $port_http = lookup('thanos::query::port_http')
  $non_puppet_managed_stores = lookup('thanos::query::non_puppet_managed::stores')

  $internal_ip = ip_for_network(lookup('internal_network'))
  $config_filepath = lookup('thanos::query::config_filepath')
  concat {$config_filepath:
    ensure         => present,
    path           => $config_filepath,
    owner          => $user,
    group          => 'prometheus',
    mode           => '0640',
    ensure_newline => true,
    order          => 'numeric',
    tag            => 'thanos',
    require        => File[$::profile::thanos::base::config_dir],
    notify         => Service[$service_name],
  }

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
  Profile::Thanos::Query_endpoint <<| |>>

  $query_arguments = {
    "http-address"           => "${internal_ip}:${port_http}",
    "store.sd-files"         => $config_filepath,
    "grpc-client-tls-secure" => true,
    "grpc-client-tls-ca"     => '/etc/ssl/certs/ca-certificates.crt',
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
    tag     => 'thanos',
  }

  $http_target  = "${swh_hostname['internal_fqdn']}:${port_http}"

  ::profile::prometheus::export_scrape_config {'thanos_query':
    target => $http_target,
  }
}
