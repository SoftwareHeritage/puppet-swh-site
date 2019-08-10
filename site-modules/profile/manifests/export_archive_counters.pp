# stats_export master class
class profile::export_archive_counters {
  $export_path = lookup('stats_export::export_path')
  $export_file = lookup('stats_export::export_file')

  $packages = ['python3-click', 'python3-requests']

  package {$packages:
    ensure => present,
  }

  $script_name = 'export_archive_counters.py'
  $script_path = "/usr/local/bin/${script_name}"

  file {$script_path:
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    source  => "puppet:///modules/profile/stats_exporter/${script_name}",
    require => Package[$packages],
  }

  $history_data_name = 'history-counters.munin.json'
  $history_data_path = "/usr/local/share/swh-data/${history_data_name}"
  file {$history_data_path:
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    source  => "puppet:///modules/profile/stats_exporter/${history_data_name}",
  }

  $server = "pergamon.internal.softwareheritage.org"
  $port = 9090

  $command_get_data = "${script_path} --server ${server} --port ${port} --history-data-file ${history_data_path}"
  cron {'stats_export':
    ensure   => present,
    user     => 'www-data',
    command  => "${command_get_data} > ${export_file}.tmp && /bin/mv ${export_file}.tmp ${export_file}",
    hour     => fqdn_rand(24, 'stats_export_hour'),
    minute   => fqdn_rand(60, 'stats_export_minute'),
    month    => '*',
    monthday => '*',
    weekday  => '*',
    require  => [
      File[$script_path],
      File[$history_data_path],
    ],
  }
}
