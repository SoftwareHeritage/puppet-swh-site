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

  concat::fragment { "${config_filepath}::header":
    target  => $config_filepath,
    content => "---\n- targets:\n",
    order   => 0,
    tag     => 'thanos',
  }

  $non_puppet_managed_stores.map | $store | {
    concat::fragment { "${config_filepath}::${store}":
      target  => $config_filepath,
      content => "  - ${store}\n",
      order   => 1,
      tag     => 'thanos',
    }
  }

  $ca_filepath = lookup('thanos::query::ca_filepath')
  concat {$ca_filepath:
    ensure         => present,
    path           => $ca_filepath,
    owner          => $user,
    group          => 'prometheus',
    mode           => '0640',
    ensure_newline => true,
    order          => 'numeric',
    tag            => 'thanos',
    require        => File[$::profile::thanos::base::config_dir],
    notify         => Service[$service_name],
  }

  concat::fragment {"${ca_filepath}::default":
    target => $ca_filepath,
    source => '/etc/ssl/certs/ca-certificates.crt',
    order  => 0,
    tag    => 'thanos',
  }

  $extra_certificates = lookup({
    name          => 'thanos::extra_certificates',
    value_type    => Array[String],
    default_value => [],
  })

  $extra_certificates.map | $index, $extra_certificate | {
    concat::fragment {"${ca_filepath}::extra_${index}":
      target  => $ca_filepath,
      content => $extra_certificate,
      order   => 0,
      tag     => 'thanos',
    }
  }

  # Deal with collected resources
  Profile::Thanos::Query_endpoint <<| |>>

  $query_arguments = {
    "http-address"           => "${internal_ip}:${port_http}",
    "store.sd-files"         => $config_filepath,
    "grpc-client-tls-secure" => true,
    "grpc-client-tls-ca"     => $ca_filepath,
  }

  $query_replica_labels = lookup('thanos::query::replica_labels')

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
