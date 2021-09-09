# Export a scrape config to the configured prometheus server
define profile::prometheus::export_scrape_config (
  String $target,
  String $job = $name,
  Optional[String] $prometheus_server = undef,
  Hash[String, String] $labels = {},
  Optional[Enum['http', 'https']] $scheme = undef,
  Optional[String] $metrics_path = undef,
  Optional[Hash[String, Array[String]]] $params = undef,
  Optional[Array[Hash[String, Variant[String, Array[String]]]]] $metric_relabel_configs = undef,
) {

  $static_labels = lookup('prometheus::static_labels', Hash)

  @@profile::prometheus::scrape_config {"${facts['swh_hostname']['short']}_${name}":
    prometheus_server      => pick($prometheus_server, lookup('prometheus::server::certname')),
    target                 => $target,
    job                    => $job,
    labels                 => $static_labels + $labels,
    scheme                 => $scheme,
    metrics_path           => $metrics_path,
    params                 => $params,
    metric_relabel_configs => $metric_relabel_configs,
  }
}
