# PostgreSQL APT configuration
class profile::postgresql::apt_config {
  $pgdg_mirror = hiera('postgresql::apt_config::pgdg::mirror')
  $pgdg_key = hiera('postgresql::apt_config::pgdg::key')
  $pglogical_mirror = hiera('postgresql::apt_config::pglogical::mirror')
  $pglogical_key = hiera('postgresql::apt_config::pglogical::key')

  ::apt::source {'pgdg':
    location => $pgdg_mirror,
    release  => "${::lsbdistcodename}-pgdg",
    repos    => 'main',
    key      => {
      content => $pgdg_key,
    },
  }

  ::apt::source {'pglogical':
    location => $pglogical_mirror,
    release  => "${::lsbdistcodename}-2ndquadrant",
    repos    => 'main',
    key      => {
      content => $pglogical_key,
    },
  }
}
