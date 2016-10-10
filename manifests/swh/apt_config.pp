# Base class for Software Heritage-specific apt configuration

class profile::swh::apt_config {
  include ::apt

  $swh_mirror_location = hiera('swh::debian_mirror::location')
  ::apt::source {'softwareheritage':
    comment        => 'Software Heritage specific package repository',
    location       => $swh_mirror_location,
    release        => $::lsbdistcodename,
    repos          => 'main',
    allow_unsigned => true,
  }

  Apt::Source <||> ~> Exec['apt_update'] -> Package <| provider == 'apt' |>

}
