# Packages to install for a borg repository

class profile::borg::packages {
  $packages = ['borg', 'borgmatic']

  package {$packages:
    ensure => installed,
  }
}
