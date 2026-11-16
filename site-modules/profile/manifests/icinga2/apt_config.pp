# Icinga2 APT configuration
class profile::icinga2::apt_config {
  $mirror = lookup('icinga2::apt_config::mirror')
  $keyid =  lookup('icinga2::apt_config::keyid')
  $key =    lookup('icinga2::apt_config::key')

  $keyring_path = '/etc/apt/keyrings/icinga2.asc'

  file { $keyring_path:
    ensure  => present,
    content => $key
  } ~> apt::source { 'icinga-stable-release':
    location => $mirror,
    release  => "icinga-${::lsbdistcodename}",
    repos    => 'main',
    keyring  => $keyring_path,
    include  => {
      src => false,
      deb => true,
    },
  }
}
