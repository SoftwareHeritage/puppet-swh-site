# Install rclone from its published deb files

class profile::rclone {
  $rclone_version = lookup('rclone::version')
  $rclone_deb_url = lookup('rclone::deb_url')
  $rclone_deb_sha256 = lookup('rclone::deb_sha256')

  $rclone_deb = "/var/cache/rclone_${rclone_version}_${facts['os']['architecture']}.deb"

  file {$rclone_deb:
    ensure         => 'present',
    owner          => 'root',
    group          => 'root',
    mode           => '0644',
    source         => $rclone_deb_url,
    checksum_value => $rclone_deb_sha256[$rclone_version][$facts['os']['architecture']],
    checksum       => 'sha256',
  }

  -> package {'rclone':
    ensure => $rclone_version,
    source => $rclone_deb,
  }
}
