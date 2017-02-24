# Icinga2 APT configuration
class profile::icinga2::apt_config {
  $mirror = hiera('icinga2::apt_config::mirror')
  $keyid =  hiera('icinga2::apt_config::keyid')
  $key =    hiera('icinga2::apt_config::key')

  apt::source { 'icinga-stable-release':
    location    => $mirror,
    release     => "icinga-${::lsbdistcodename}",
    repos       => 'main',
    key         => {
      id      => $keyid,
      content => $key,
      },
    include_src => false,
  }
}
