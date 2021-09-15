# APT configuration for hedgedoc
class profile::hedgedoc::apt_config {
  include profile::nodejs::apt_config

  $packages = [
    'npm', 'yarn', 'node-gyp', 'nodejs'
  ]

  $keyid = lookup('yarn::apt_config::keyid')
  $key =   lookup('yarn::apt_config::key')

  apt::source { 'yarn':
    location => "https://dl.yarnpkg.com/debian/",
    release  => 'stable',
    repos    => 'main',
    key      => {
      id      => $keyid,
      content => $key,
    },
  }

  package { $packages:
    ensure => latest,
    notify => Service['hedgedoc'],
  }
}
