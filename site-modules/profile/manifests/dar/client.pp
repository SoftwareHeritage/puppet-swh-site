class profile::dar::client {
  $directory = lookup('backups::legacy_storage')

  file {$directory:
    ensure  => 'absent',
    purge   => true,
    recurse => true,
  }

  exec {'sed -e /dar\./d -e /swh-dar-backup/d -i /var/spool/cron/crontabs/root':
    path   => ['/sbin', '/usr/sbin', '/bin', '/usr/bin'],
    onlyif => 'grep -q swh-dar-backup /var/spool/cron/crontabs/root',
  }

  file {'/usr/local/bin/swh-dar-backup':
    ensure => absent,
  }

  file {'/var/log/dar':
    ensure => absent,
    purge   => true,
    recurse => true,
  }

  file {'/etc/logrotate.d/swh-dar':
    ensure => absent,
  }
}
