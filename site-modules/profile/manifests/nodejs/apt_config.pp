# NodeJS APT configuration
class profile::nodejs::apt_config {
  $keyid = lookup('nodejs::apt_config::keyid')
  $key = lookup('nodejs::apt_config::key')
  $version = lookup('nodejs::version')

  if $facts['lsbdistcodename'] == 'bookworm' {
    ::apt::pin {'nodejs':
      explanation => 'Pin nodejs to nodejs_16 source',
      priority    => 990,
      version     => "16.*",
      packages    => "nodejs",
    }
  }

  ::apt::source {'nodejs':
    location => "https://deb.nodesource.com/node_${version}",
    release  => "${::lsbdistcodename}",
    repos    => 'main',
    key      => {
      id      => $keyid,
      content => $key,
    },
  }
}
