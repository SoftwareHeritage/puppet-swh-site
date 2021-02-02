# APT configuration for hedgedoc
class profile::hedgedoc::apt_config {
  $packages = [
    'npm', 'yarn', 'node-gyp'
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
  } ->
  package { $packages:
    ensure => present,
    notify => Archive['hedgedoc'],
  }
}
