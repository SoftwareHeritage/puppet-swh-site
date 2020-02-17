# Scrape configuration for a prometheus exporter
define profile::prometheus::scrape_config (
  String $prometheus_server,
  String $target,
  String $job,
  Hash[String, String] $labels = {},
  Optional[Enum['http', 'https']] $scheme = undef,
  Optional[String] $metrics_path = undef,
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
          job_name     => $job,
          targets      => [$target],
          labels       => $labels,
          scheme       => $scheme,
          metrics_path => $metrics_path
        },
      ]
    ),
    notify  => Exec['update-prometheus-config'],
  }
}
