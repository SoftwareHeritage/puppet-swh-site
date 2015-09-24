# systemd-specific stuff for Software Heritage
class profile::swh::systemd {
  exec {'systemd-daemon-reload':
    path        => '/sbin:/usr/sbin:/bin:/usr/bin',
    command     => 'systemctl daemon-reload',
    refreshonly => true,
  }
}
