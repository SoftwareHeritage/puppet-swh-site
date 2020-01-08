class profile::dar::server {
  file {'/usr/local/bin/swh-dar-copy-remote-backup':
    ensure => 'absent',
  }

  exec {'sed -e /dar_remote_backup/d -e /swh-dar-copy-remote-backup/d -i /var/spool/cron/crontabs/root':
    path   => ['/sbin', '/usr/sbin', '/bin', '/usr/bin'],
    onlyif => 'grep -q swh-dar-copy-remote-backup /var/spool/cron/crontabs/root',
  }
}
