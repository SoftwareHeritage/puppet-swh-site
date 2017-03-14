# Manage the configuration of apt for the systemd journal
class profile::systemd_journal::apt_config {
  if $::lsbdistcodename == 'jessie' {
    $pinned_packages = [
      'apparmor',
      'ifupdown',
      'libapparmor1',
      'libseccomp2',
      'libsystemd0',
      'libudev1',
      'systemd',
      'systemd-journal-remote',
      'systemd-sysv',
      'udev',
    ]

    ::apt::pin {'systemd':
      explanation => 'Pin systemd dependencies to backports',
      codename    => 'jessie-backports',
      packages    => $pinned_packages,
      priority    => 990,
    }
  }
}
