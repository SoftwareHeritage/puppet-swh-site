class profile::dar::client {
  include ::dar

  $hour     = hiera('dar::cron::hour')
  if $hour == 'fqdn_rand' {
    $hour = fqdn_rand(24, "backup_hour")
  }

  $minute   = hiera('dar::cron::minute')
  if $minute == 'fqdn_rand' {
    $minute = fqdn_rand(60, "backup_minute")
  }

  $month    = hiera('dar::cron::month')
  if $month == 'fqdn_rand' {
    $month = fqdn_rand(12, "backup_month")
  }

  $monthday = hiera('dar::cron::monthday')
  if $monthday == 'fqdn_rand' {
    $monthday = fqdn_rand(31, "backup_monthday")
  }

  $weekday  = hiera('dar::cron::weekday')
  if $weekday == 'fqdn_rand' {
    $weekday = fqdn_rand(31, "backup_weekday")
  }

  dar::backup { $::hostname:
    backup_storage   => hiera('dar::backup::storage'),
    keep_backups     => hiera('dar::backup::num_backups'),
    backup_base      => hiera('dar::backup::base'),
    backup_selection => hiera('dar::backup::select'),
    backup_exclusion => hiera('dar::backup::exclude'),
    backup_options   => hiera('dar::backup::options'),
    hour             => $hour,
    minute           => $minute,
    month            => $month,
    monthday         => $monthday,
    weekday          => $weekday,
  }
}
