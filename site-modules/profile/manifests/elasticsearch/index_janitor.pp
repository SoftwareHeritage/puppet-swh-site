# Elasticsearch index janitor
class profile::elasticsearch::index_janitor {
  $elasticsearch_nodes = lookup('swh::elasticsearch::storage_nodes')

  $packages = ['python3-click', 'python3-elasticsearch', 'python3-iso8601']

  package {$packages:
    ensure => present,
  }

  $script_name = 'elasticsearch_close_index.py'
  $script_path = "/usr/local/bin/${script_name}"

  file {$script_path:
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    source  => "puppet:///modules/profile/elasticsearch/${script_name}",
    require => Package[$packages],
  }

  $elasticsearch_hosts = $elasticsearch_nodes.map |$host_info| { $host_info['host'] }
  $flag_es_hosts = join($elasticsearch_hosts, " --host ")

  profile::cron::d {'elasticsearch-close-index':
    target  => 'elasticsearch',
    command => "chronic sh -c '${script_path} --host ${flag_es_hosts} --timeout 1200'",
    user    => 'root',
    minute  => 'fqdn_rand',
    hour    => 'fqdn_rand',
  }
}
