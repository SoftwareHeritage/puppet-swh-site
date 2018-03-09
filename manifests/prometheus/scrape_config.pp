# Scrape configuration for a prometheus exporter
define profile::prometheus::scrape_config (
  String $prometheus_server,
  String $target,
  String $job,
  Hash[String, String] $labels = {},

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
          targets => [$target],
          labels  => {
            job => $job,
          } + $labels,
        },
      ]
    ),
  }
}
