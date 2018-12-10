class profile::dar::client {
  include ::dar

  $dar_remote_hostname = $::swh_hostname['short']
  $dar_backup_name = $::hostname

  $backup_cron = profile::cron_rand(lookup('dar::cron', Hash), 'backup')

  dar::backup { $dar_backup_name:
    backup_storage   => lookup('dar::backup::storage'),
    keep_backups     => lookup('dar::backup::num_backups'),
    backup_base      => lookup('dar::backup::base'),
    backup_selection => lookup('dar::backup::select'),
    backup_exclusion => lookup('dar::backup::exclude', Array, 'unique'),
    backup_options   => lookup('dar::backup::options'),
    *                => $backup_cron,
  }

  $server_cron = profile::cron_rand(lookup('dar_server::cron', Hash), 'backup_server')

  # Export a remote backup to the backup server
  @@dar::remote_backup { "${dar_remote_hostname}.${dar_backup_name}":
    remote_backup_storage => lookup('dar::backup::storage'),
    remote_backup_host    => $dar_remote_hostname,
    remote_backup_name    => $dar_backup_name,
    local_backup_storage  => lookup('dar_server::backup::storage'),
    *                     => $server_cron,
  }
}
