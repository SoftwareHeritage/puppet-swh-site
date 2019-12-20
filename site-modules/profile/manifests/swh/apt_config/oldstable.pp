# Configure oldstable repositories
class profile::swh::apt_config::oldstable {
  $debian_mirror = lookup('swh::apt_config::debian_mirror')
  $debian_security_mirror = lookup('swh::apt_config::debian_security_mirror')

  $oldstable = $::lsbdistcodename ? {
    'buttercup' => 'bullseye',
    'bullseye'  => 'buster',
    'buster'    => 'stretch',
    'stretch'   => 'jessie',
    default     => 'stretch',
  }

  ::apt::source {'oldstable':
    location => $debian_mirror,
    release  => $oldstable,
    repos    => 'main',
  }

  ::apt::source {'oldstable-updates':
    location => $debian_mirror,
    release  => "${oldstable}-updates",
    repos    => 'main',
  }

  ::apt::source {'oldstable-security':
    location => $debian_security_mirror,
    release  => "${oldstable}/updates",
    repos    => 'main',
  }

  ::apt::pin {'oldstable':
    explanation => 'Pin olstable to low priority',
    codename    => "${oldstable}*",
    packages    => '*',
    priority    => 100,
  }
}

