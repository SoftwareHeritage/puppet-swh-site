# deploy a hedgedoc instance
class profile::hedgedoc {

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
  }

  ensure_packages ( $packages )

  # packages { $packages:
  #   ensure => present,
  #   require => Apt::source['yarn'],
  # }
}
s
