class profile::dar::client {
  include ::dar

  $backup_enable = lookup('dar::backup::enable')

  if $backup_enable {
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

    $dir_for_fetched_backups = lookup('dar_server::backup::storage')
    $central_backup_host = lookup('dar_server::central_host')

    # Export a remote backup to the backup server
    @@dar::remote_backup { "${dar_remote_hostname}.${dar_backup_name}":
      remote_backup_storage => lookup('dar::backup::storage'),
      remote_backup_host    => $dar_remote_hostname,
      remote_backup_name    => $dar_backup_name,
      local_backup_storage  => $dir_for_fetched_backups,
      *                     => $server_cron,
    }

    # Export an icinga check to verify backup freshness
    $icinga_checks_file = '/etc/icinga2/conf.d/exported-checks.conf'
    $checked_directory = "${dir_for_fetched_backups}/${dar_remote_hostname}"

    @@::icinga2::object::service {"backup freshness for ${dar_remote_hostname}":
      service_name     => 'backup freshness',
      import           => ['generic-service'],
      host_name        => $::fqdn,
      command_endpoint => $central_backup_host,
      check_command    => 'check_newest_file_age',
      check_interval   => '10h',
      vars             => {
        check_directory => $checked_directory,
      },
      target           => $icinga_checks_file,
      tag              => 'icinga2::exported',
    }
  }
}
