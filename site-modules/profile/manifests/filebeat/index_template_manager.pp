# Ensure the index template of the current 
# filebeat version is declared in elasticsearch
class profile::filebeat::index_template_manager {
  $default_elk_version = lookup('elastic::elk_version')
  $version = lookup('elastic::beat_version', { default_value => $default_elk_version })

  $template_management_script = '/usr/local/bin/manage_index_template.sh'
  $filebeat_templates = '/var/lib/filebeat-templates'
  $es_node = lookup('swh::elasticsearch::storage_nodes')[0]
  $es_node_url = "${es_node['host']}:${es_node['port']}"

  $filebeat_indexes = [
    'systemlogs',
    'swh_workers',
  ]

  file { $template_management_script:
    ensure => present,
    owner  => 'root',
    group  => 'root',
    mode   => '0544',
    source => 'puppet:///modules/profile/filebeat/manage_index_template.sh',
  }

  file {$filebeat_templates:
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

  each($filebeat_indexes) |$index| {
    $template_name = "${index}-${version}"
    $index_template = "${template_name}-*"

    exec {"check ${index} template":
      command => "${template_management_script} ${es_node_url} ${template_name} ${index_template}",
      cwd     => '/usr/local/bin',
      creates => "${filebeat_templates}/${index}-${version}.json",
      user    => 'root',
      require => [
        Package['filebeat'],
        File[$template_management_script],
      ],
      before  => [Service['filebeat']]
    }
  }
}
