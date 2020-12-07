# Elasticsearch cluster node profile

class profile::elasticsearch {

  include ::profile::elastic::apt_config

  $elasticsearch_config = lookup('elasticsearch::config')
  $elasticsearch_extra_config = lookup('elasticsearch::config::extras', {default_value => {}})
  $version = lookup('elastic::elk_version')

  $path_data = lookup('elasticsearch::config::path::data')
  $jvm_options = lookup('elasticsearch::jvm_options')

  # for the prometheus exporter
  $elasticsearch_http_port = lookup('elasticsearch::config::http::port')
  $elasticsearch_cluster_name = lookup('elasticsearch::config::cluster::name')

  apt::pin { 'elasticsearch':
    packages => 'elasticsearch elasticsearch-oss',
    version  => $version,
    priority => 1001,
  } -> package { 'elasticsearch':
    ensure  => $version,
    require => [
      Class['::profile::elastic::apt_config']
    ]
  }

  file { $path_data:
    ensure  => 'directory',
    owner   => 'elasticsearch',
    group   => 'elasticsearch',
    mode    => '2755',
    require => Package['elasticsearch']
  }

  $config = $elasticsearch_config + $elasticsearch_extra_config + {
    'network.host' => ip_for_network(lookup('internal_network'))
  }

  file { '/etc/elasticsearch/elasticsearch.yml':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => inline_yaml($config),
    require => Package['elasticsearch'],
    notify  => Service['elasticsearch'],
  }

  concat {'es_jvm_options':
    ensure         => present,
    path           => '/etc/elasticsearch/jvm.options.d/jvm.options',
    owner          => 'root',
    group          => 'root',
    mode           => '0644',
    ensure_newline => true,
    require        => Package['elasticsearch'],
    notify         => Service['elasticsearch'],
  }

  $jvm_options.each |$index, $option| {
    concat::fragment {"${index}_es_jvm_option":
      target  => 'es_jvm_options',
      content => $option,
      order   => '00',
    }
  }

  systemd::dropin_file { 'elasticsearch.conf':
    unit    => 'elasticsearch.service',
    content => template('profile/swh/elasticsearch.conf.erb'),
    notify  => Service['elasticsearch'],
  }

  service { 'elasticsearch':
    ensure  => running,
    enable  => true,
    require => [
      Package['elasticsearch'],
      File[$path_data],
    ],
  }

  include profile::prometheus::elasticsearch

  profile::prometheus::export_scrape_config {"elasticsearch_${::fqdn}":
    job          => 'elasticsearch',
    target       => "${::fqdn}:${elasticsearch_http_port}",
    scheme       => 'http',
    metrics_path => '/_prometheus/metrics',
  }
}
