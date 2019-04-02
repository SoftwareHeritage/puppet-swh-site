class profile::prometheus::jmx {
  $base_directory = '/opt/prometheus-jmx-exporter'
  $version = lookup('prometheus::jmx::version')

  $jar_name = "jmx_prometheus_javaagent-${version}.jar"
  $upstream_url = "https://repo1.maven.org/maven2/io/prometheus/jmx/jmx_prometheus_javaagent/${version}/${jar_name}"
  $jar_path = "${base_directory}/${jar_name}"

  file {$base_directory:
    ensure => 'directory',
    mode   => '0644',
    owner  => 'root',
    group  => 'root',
  }

  file {$jar_path:
    ensure => 'present',
    owner  => 'root',
    group  => 'root',
    source => $upstream_url,
  }
}
