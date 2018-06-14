class profile::dar::client {
  include ::dar

  $dar_remote_hostname = $::swh_hostname['short']
  $dar_backup_name = $::hostname

  $hierahour     = lookup('dar::cron::hour')
  if $hierahour == 'fqdn_rand' {
    $hour = fqdn_rand(24, 'backup_hour')
  } else {
    $hour = $hierahour
  }

  $hieraminute   = lookup('dar::cron::minute')
  if $hieraminute == 'fqdn_rand' {
    $minute = fqdn_rand(60, 'backup_minute')
  } else {
    $minute = $hieraminute
  }

  $hieramonth    = lookup('dar::cron::month')
  if $hieramonth == 'fqdn_rand' {
    $month = fqdn_rand(12, 'backup_month')
  } else {
    $month = $hieramonth
  }

  $hieramonthday = lookup('dar::cron::monthday')
  if $hieramonthday == 'fqdn_rand' {
    $monthday = fqdn_rand(31, 'backup_monthday')
  } else {
    $monthday = $hieramonthday
  }

  $hieraweekday  = lookup('dar::cron::weekday')
  if $hieraweekday == 'fqdn_rand' {
    $weekday = fqdn_rand(31, 'backup_weekday')
  } else {
    $weekday = $hieraweekday
  }

  dar::backup { $dar_backup_name:
    backup_storage   => lookup('dar::backup::storage'),
    keep_backups     => lookup('dar::backup::num_backups'),
    backup_base      => lookup('dar::backup::base'),
    backup_selection => lookup('dar::backup::select'),
    backup_exclusion => lookup('dar::backup::exclude', Array, 'unique'),
    backup_options   => lookup('dar::backup::options'),
    hour             => $hour,
    minute           => $minute,
    month            => $month,
    monthday         => $monthday,
    weekday          => $weekday,
  }

  # Export a remote backup to the backup server
  @@dar::remote_backup { "${dar_remote_hostname}.${dar_backup_name}":
    remote_backup_storage => lookup('dar::backup::storage'),
    remote_backup_host    => $dar_remote_hostname,
    remote_backup_name    => $dar_backup_name,
    local_backup_storage  => lookup('dar_server::backup::storage'),
    hour                  => lookup('dar_server::cron::hour'),
    minute                => lookup('dar_server::cron::minute'),
    month                 => lookup('dar_server::cron::month'),
    monthday              => lookup('dar_server::cron::monthday'),
    weekday               => lookup('dar_server::cron::weekday'),
  }
}
