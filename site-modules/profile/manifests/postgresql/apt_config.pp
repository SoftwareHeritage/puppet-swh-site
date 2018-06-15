# PostgreSQL APT configuration
class profile::postgresql::apt_config {
  $pgdg_mirror = lookup('postgresql::apt_config::pgdg::mirror')
  $pgdg_keyid = lookup('postgresql::apt_config::pgdg::keyid')
  $pgdg_key = lookup('postgresql::apt_config::pgdg::key')
  $pglogical_mirror = lookup('postgresql::apt_config::pglogical::mirror')
  $pglogical_keyid = lookup('postgresql::apt_config::pglogical::keyid')
  $pglogical_key = lookup('postgresql::apt_config::pglogical::key')

  ::apt::source {'pgdg':
    location => $pgdg_mirror,
    release  => "${::lsbdistcodename}-pgdg",
    repos    => 'main',
    key      => {
      id      => $pgdg_keyid,
      content => $pgdg_key,
    },
  }

  ::apt::source {'pglogical':
    location => $pglogical_mirror,
    release  => "${::lsbdistcodename}-2ndquadrant",
    repos    => 'main',
    key      => {
      id      => $pglogical_keyid,
      content => $pglogical_key,
    },
  }
}
