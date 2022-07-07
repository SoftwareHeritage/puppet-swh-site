# Define exported resource for a thanos query/gateway endpoint
define profile::thanos::export_query_endpoint (
  String $grpc_address,
) {

  @@::profile::thanos::query_endpoint{"${facts['swh_hostname']['short']}_${name}":
    grpc_address => $grpc_address
  }
}
