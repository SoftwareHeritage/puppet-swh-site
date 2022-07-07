# Define concrete resource for a thanos query/gateway endpoint
define profile::thanos::query_endpoint (
  String $grpc_address,
) {

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
    require        => File[$::profile::thanos::base::config_dir]
  }

  # sidecar grpc address pushed to query service configuration file
  concat::fragment { $grpc_address:
    target  => $config_filepath,
    content => "  - ${grpc_address}\n",
    order   => 2,
    tag     => 'thanos',
  }

}
