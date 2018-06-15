# Manage base PHP installation
class profile::php {
  $php_mirror = lookup('php::apt_config::mirror')
  $php_keyid = lookup('php::apt_config::keyid')
  $php_key = lookup('php::apt_config::key')

  ::apt::source {'php':
    location => $php_mirror,
    release  => $facts['os']['distro']['codename'],
    repos    => 'main',
    key      => {
      id      => $php_keyid,
      content => $php_key,
    },
  }

  $php_version = lookup('php::version')

  class {'::php::globals':
    php_version => $php_version,
  }
  -> class {'::php':
    manage_repos => false,
    dev          => false,
    composer     => false,
    pear         => false,
    fpm          => false,
  }
  class {'::php::fpm':
    pools => {},
  }

  package {"php${php_version}-mysql":
    ensure => installed,
  }
  -> ::php::extension {['mysqlnd', 'mysqli', 'pdo_mysql']:
    provider => 'none',
  }

}
