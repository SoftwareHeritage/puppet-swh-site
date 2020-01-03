# Packages to install for a borg repository

class profile::borg::packages {
  $packages = ['borgbackup', 'borgmatic']

  package {$packages:
    ensure => installed,
  }
}
