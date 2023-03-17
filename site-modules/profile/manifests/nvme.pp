# Set up for nvme devices
class profile::nvme {
  if ($::disks.keys.filter |$name| { $name =~ /^nvme/ }.length > 0) {
    ensure_packages('nvme-cli')
  }
}
