# Install smart monitoring tools on physical machines
class profile::smartmontools {
  $packages = ["smartmontools"]

  package {$packages:
    ensure => $::virtual ? { 'physical' => 'installed', default => 'purged' }
  }

}
