# stats_export master class
class profile::munin::stats_export {
  $export_path = lookup('stats_export::export_path')
  $export_file = lookup('stats_export::export_file')

  $packages = ['python3-click']

  package {$packages:
    ensure => present,
  }

  file {'/usr/local/bin/export-rrd':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    source  => 'puppet:///modules/profile/munin/stats_export/export-rrd',
    require => Package[$packages],
  }

  cron {'stats_export':
    ensure   => present,
    user     => 'www-data',
    command  => "/usr/local/bin/export-rrd > ${export_file}.tmp && /bin/mv ${export_file}.tmp ${export_file}",
    hour     => fqdn_rand(24, 'stats_export_hour'),
    minute   => fqdn_rand(60, 'stats_export_minute'),
    month    => '*',
    monthday => '*',
    weekday  => '*',
    require  => [
      File['/usr/local/bin/export-rrd'],
    ],
  }
}
