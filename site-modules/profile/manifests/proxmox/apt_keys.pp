# Proxmox APT keys configuration
class profile::proxmox::apt_keys {
  $proxmox_keys = {
    '5.x' => lookup('proxmox::apt_config::key::5_x'),
    '6.x' => lookup('proxmox::apt_config::key::6_x'),
  }

  $proxmox_keys.each |$release, $content| {
    file {"/etc/apt/trusted.gpg.d/proxmox-ve-release-${release}.asc":
      ensure  => present,
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => $content,
      tag     => 'proxmox',
    } -> Apt::Source <| tag == 'proxmox' |>
  }
}
