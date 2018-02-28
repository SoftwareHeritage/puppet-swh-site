# Icinga2 APT configuration
class profile::icinga2::apt_config {
  $mirror = lookup('icinga2::apt_config::mirror')
  $keyid =  lookup('icinga2::apt_config::keyid')
  $key =    lookup('icinga2::apt_config::key')

  apt::source { 'icinga-stable-release':
    location => $mirror,
    release  => "icinga-${::lsbdistcodename}",
    repos    => 'main',
    key      => {
      id      => $keyid,
      content => $key,
      },
    include  => {
      src => false,
      deb => true,
    },
  }
}
