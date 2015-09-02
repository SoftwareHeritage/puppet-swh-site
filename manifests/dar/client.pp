class profile::dar::client {
  include ::dar

  dar::backup { $::hostname:
    backup_storage   => hiera('dar::backup::storage'),
    hour             => hiera('dar::cron::hour'),
    minute           => hiera('dar::cron::minute'),
    month            => hiera('dar::cron::month'),
    monthday         => hiera('dar::cron::monthday'),
    weekday          => hiera('dar::cron::weekday'),
    keep_backups     => hiera('dar::backup::num_backups'),
    backup_base      => hiera('dar::backup::base'),
    backup_selection => hiera('dar::backup::select'),
    backup_exclusion => hiera('dar::backup::exclude'),
    backup_options   => hiera('dar::backup::options'),
  }
}
