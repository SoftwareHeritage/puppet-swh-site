# Proxmox APT repository configuration
class profile::proxmox::apt_config {
  include ::profile::proxmox::apt_keys

  ::apt::source {'pve-install-repo':
    ensure   => 'present',
    location => 'http://download.proxmox.com/debian/pve',
    release  => $::facts['os']['distro']['codename'],
    repos    => 'pve-no-subscription',
    tag      => 'proxmox',
  }
}
