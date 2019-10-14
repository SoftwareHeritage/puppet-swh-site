# Proxmox APT keys configuration
class profile::proxmox::apt_keys {
  $proxmox_key = lookup('proxmox::apt_config::key::6_x')

  file {'/etc/apt/trusted.gpg.d/proxmox-ve-release-6.x.asc':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => $proxmox_key,
  } -> Apt::Source <| tag == 'proxmox' |>
}
