# Install and configure Anubis

class profile::anubis {
  $anubis_version = lookup('anubis::version')
  $anubis_deb_url = lookup('anubis::deb_url')
  $anubis_deb_sha256 = lookup('anubis::deb_sha256')

  $anubis_deb = "/var/cache/anubis_${anubis_version}_${facts['os']['architecture']}.deb"

  file {$anubis_deb:
    ensure         => 'present',
    owner          => 'root',
    group          => 'root',
    mode           => '0644',
    source         => $anubis_deb_url,
    checksum_value => $anubis_deb_sha256[$anubis_version][$facts['os']['architecture']],
    checksum       => 'sha256',
  }

  -> package {'anubis':
    ensure => $anubis_version,
    source => $anubis_deb,
    notify => Class['systemd::systemctl::daemon_reload'],
  }

  $anubis_files = ['common-bots.yaml']

  $anubis_files.each |$file| {
    file {"/etc/anubis/${file}":
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      source  => "puppet:///modules/profile/anubis/${file}",
      require => Package['anubis'],
    } ~> Service <| tag == "anubis" |>
  }
}
