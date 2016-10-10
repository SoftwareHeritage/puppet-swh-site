# Base class for Software Heritage-specific apt configuration

class profile::swh::apt_config {
  include ::apt

  class {'::apt::backports':
    pin => 100,
  }

  $swh_mirror_location = hiera('swh::debian_mirror::location')
  ::apt::source {'softwareheritage':
    comment        => 'Software Heritage specific package repository',
    location       => $swh_mirror_location,
    release        => $::lsbdistcodename,
    repos          => 'main',
    allow_unsigned => true,
    notify_update  => true,
  }

  Class['apt::update'] -> Package <| provider == 'apt' |>

}
