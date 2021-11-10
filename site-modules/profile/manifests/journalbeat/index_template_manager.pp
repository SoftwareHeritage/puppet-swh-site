# Ensure the index template of the current 
# filebeat version is declared in elasticsearch
class profile::journalbeat::index_template_manager {
  $default_elk_version = lookup('elastic::elk_version')
  $version = lookup('elastic::beat_version', { default_value => $default_elk_version })

  $template_management_script = '/usr/local/bin/manage_index_template.sh'
  $journalbeat_home = '/var/lib/journalbeat'
  $es_node = lookup('swh::elasticsearch::storage_nodes')[0]
  $es_node_url = "${es_node['host']}:${es_node['port']}"

  $journalbeat_indexes = [
    'systemlogs',
    'swh_workers',
  ]

  file { $template_management_script:
    ensure => present,
    owner  => 'root',
    group  => 'root',
    mode   => '0544',
    source => 'puppet:///modules/profile/journalbeat/manage_index_template.sh',
  }

  each($journalbeat_indexes) |$index| {
    $template_name = "${index}-${version}"
    $index_template = "${template_name}-*"

    exec {"check ${index} template":
      command => "${template_management_script} ${es_node_url} ${template_name} ${index_template}",
      cwd     => '/usr/local/bin',
      creates => "${journalbeat_home}/${index}-${version}.json",
      user    => 'root',
      require => [
        Package['journalbeat'],
        File[$template_management_script],
      ],
      before  => [Service['journalbeat']]
    }
  }
}
