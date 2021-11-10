# Deployment of prometheus elasticsearch exporter

class profile::prometheus::elasticsearch {
  include profile::prometheus::base

  $version = lookup('prometheus::elasticsearch::exporter::version')

  $archive_url = "https://github.com/vvanholl/elasticsearch-prometheus-exporter/releases/download/${version}/prometheus-exporter-${version}.zip"
  $plugin_path = '/usr/share/elasticsearch/plugins/prometheus-exporter'

  exec {'cleanup prometheus exporter plugin':
    creates => "${plugin_path}/prometheus-exporter-${version}.jar",
    command => "/usr/bin/rm -rf ${plugin_path}",
  } -> file { $plugin_path:
    ensure  => directory,
    owner   => 'elasticsearch',
    group   => 'elasticsearch',
    mode    => '0755',
    require => Package['elasticsearch']
  }
  -> archive { 'prometheus-elasticsearch-exporter':
    path         => "/tmp/prometheus-exporter-${version}.zip",
    source       => $archive_url,
    extract      => true,
    extract_path => $plugin_path,
    creates      => "${plugin_path}/prometheus-exporter-${version}.jar",
    cleanup      => true,
    user         => 'root',
    group        => 'root',
    require      => [
      Package['elasticsearch'],
    ],
  }


  Archive['prometheus-elasticsearch-exporter'] ~> Service['elasticsearch']
}
