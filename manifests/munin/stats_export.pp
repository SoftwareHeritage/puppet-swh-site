# stats_export master class
class profile::munin::stats_export {
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
}
