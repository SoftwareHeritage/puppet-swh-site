class profile::dar::client {
  include ::dar

  $hierahour     = hiera('dar::cron::hour')
  if $hierahour == 'fqdn_rand' {
    $hour = fqdn_rand(24, 'backup_hour')
  } else {
    $hour = $hierahour
  }

  $hieraminute   = hiera('dar::cron::minute')
  if $hieraminute == 'fqdn_rand' {
    $minute = fqdn_rand(60, 'backup_minute')
  } else {
    $minute = $hieraminute
  }

  $hieramonth    = hiera('dar::cron::month')
  if $hieramonth == 'fqdn_rand' {
    $month = fqdn_rand(12, 'backup_month')
  } else {
    $month = $hieramonth
  }

  $hieramonthday = hiera('dar::cron::monthday')
  if $hieramonthday == 'fqdn_rand' {
    $monthday = fqdn_rand(31, 'backup_monthday')
  } else {
    $monthday = $hieramonthday
  }

  $hieraweekday  = hiera('dar::cron::weekday')
  if $hieraweekday == 'fqdn_rand' {
    $weekday = fqdn_rand(31, 'backup_weekday')
  } else {
    $weekday = $hieraweekday
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
