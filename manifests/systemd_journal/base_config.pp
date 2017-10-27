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
    command => 'systemd-tmpfiles --create --prefix /var/log/journal',
    path    => ['/sbin', '/usr/sbin', '/bin', '/usr/bin'],
    require => [
      File['/var/log/journal'],
      Package['acl'],
    ],
    unless  => 'getfacl -csp /var/log/journal | grep -Eq group:adm:r-x',
  }
}
