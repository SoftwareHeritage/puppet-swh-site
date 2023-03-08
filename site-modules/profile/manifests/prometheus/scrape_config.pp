# Scrape configuration for a prometheus exporter
define profile::prometheus::scrape_config (
  String $prometheus_server,
  String $target,
  String $job,
  Hash[String, String] $labels = {},
  Optional[Enum['http', 'https']] $scheme = undef,
  Optional[String] $metrics_path = undef,
  Optional[Hash[String, Array[String]]] $params = undef,
  Optional[Array[Hash[String, Variant[String, Array[String]]]]] $metric_relabel_configs = undef,
  Optional[String] $scrape_interval = '1m',
  Optional[String] $scrape_timeout = '45s',
){
  $directory = $profile::prometheus::server::scrape_configs_dir
  file {"${directory}/${name}.yaml":
    ensure  => 'present',
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => inline_yaml(
      [
        {
          job_name               => $job,
          targets                => [$target],
          labels                 => $labels,
          scheme                 => $scheme,
          metrics_path           => $metrics_path,
          params                 => $params,
          metric_relabel_configs => $metric_relabel_configs,
          scrape_interval        => $scrape_interval,
          scrape_timeout         => $scrape_timeout,
        },
      ]
    ),
    notify  => Exec['update-prometheus-config'],
  }
}
