# Manage systemd-journald base configuration
class profile::systemd_journal::base_config {
  file {'/var/log/journal':
    ensure => 'directory',
    owner  => 'root',
    group  => 'systemd-journal',
    mode   => '2755',
    notify => Exec['systemd_journal-tmpdir'],
  }

  exec {'systemd_journal-tmpdir':
    command     => 'systemd-tmpfiles --create --prefix /var/log/journal',
    path        => ['/sbin', '/usr/sbin'],
    refreshonly => true,
  }
}
