# Define concrete resource for a thanos query/gateway endpoint
define profile::thanos::query_endpoint (
  String $grpc_address,
) {

  $config_filepath = lookup('thanos::query::config_filepath')

  # sidecar grpc address pushed to query service configuration file
  concat::fragment {"${config_filepath}-${grpc_address}":
    target  => $config_filepath,
    content => "  - ${grpc_address}\n",
    order   => 2,
  }

}
