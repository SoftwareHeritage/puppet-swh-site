# Borg backup client setup
class profile::borg::client {

  $backup_enable = lookup('backups::enable')

  if $backup_enable {

    include profile::borg::packages

    $fqdn = $::swh_hostname['internal_fqdn']

    $seed = lookup('borg::passphrase::seed')
    $passphrase = seeded_rand_string(16, "borg::passphrase::${seed}::${fqdn}")

    $encryption = lookup('borg::encryption')

    $repo_user = lookup('borg::repository_user')
    $repo_hostname = lookup('borg::repository_server')
    $repo_path = lookup('borg::repository_path')

    $base_dir = '/var/lib/borg'

    file {$base_dir:
      ensure => directory,
      mode   => '0600',
      owner  => 'root',
      group  => 'root',
    }

    $ssh_key_type = 'ed25519'
    $ssh_key_basename = "id_${ssh_key_type}.borg"
    $ssh_key_pubname = "${ssh_key_basename}.pub"
    $ssh_key_file = "/root/.ssh/${ssh_key_basename}"

    exec {"ssh-keygen -t ${ssh_key_type} -f ${ssh_key_file} -N ''":
      path    => ['/bin', '/usr/bin'],
      creates => $ssh_key_file,
    }

    $sshkey_installed = $ssh_keys_users and $ssh_keys_users['root'] and $ssh_keys_users['root'][$ssh_key_pubname]

    if $sshkey_installed {
      $key = $ssh_keys_users['root'][$ssh_key_pubname]
      @@profile::borg::repository {$fqdn:
        passphrase     => $passphrase,
        encryption     => $encryption,
        authorized_key => "ssh-${key['type']} ${key['key']} ${key['comment']}",
        tag            => $repo_hostname,
      }
    }

    $backup_base = lookup('backups::base')
    $backup_excludes = lookup('backups::exclude', Array, 'unique').map |$d| { "${backup_base}${d}" }

    $borgmatic_config = {
      location => {
        source_directories => [$backup_base],
        repositories       => ["${repo_user}@${repo_hostname}:${repo_path}/${fqdn}"],
        exclude_patterns   => $backup_excludes + [$base_dir],
        exclude_caches     => true,
        exclude_if_present => '.nobackup',
      },
      storage => {
        ssh_command           => "ssh -i ${ssh_key_file}",
        encryption_passphrase => $passphrase,
        borg_base_directory   => $base_dir,
        archive_name_format   => "${fqdn}-{now:%Y-%m-%dT%H:%M:%S.%f}",
      },
      retention => {
        keep_hourly  => 24,
        keep_daily   => 7,
        keep_weekly  => 4,
        keep_monthly => 6,
        prefix       => "${fqdn}-",
      },
      consistency => {
        prefix       => "${fqdn}-",
      },
    }

    file {'/etc/borgmatic':
      ensure => 'directory',
      owner  => 'root',
      group  => 'root',
      mode   => '0600',
    }

    file {'/etc/borgmatic/config.yaml':
      ensure  => 'present',
      owner   => 'root',
      group   => 'root',
      mode    => '0600',  # contains passphrase
      content => inline_yaml($borgmatic_config),
      require => Package['borgmatic'],
    }


    # Generate a static minute and hour on which to run the full borgmatic for the
    # given host
    $crontime = profile::cron_rand({
      minute => 'fqdn_rand',
      hour   => 'fqdn_rand',
    }, 'borgmatic')

    # List all other hours in the day
    $cronhours = delete(range(0, 23), $crontime['hour'])

    if $sshkey_installed {
      # Run borgmatic create once every hour
      profile::cron::d {'borgmatic-create':
        target  => 'borgmatic',
        minute  => $crontime['minute'],
        hour    => $cronhours,
        command => 'borgmatic create',
      }

      # Do a full borgmatic run every day
      profile::cron::d {'borgmatic-full':
        target  => 'borgmatic',
        minute  => $crontime['minute'],
        hour    => $crontime['hour'],
        command => 'borgmatic',
      }
    }
  }
}
