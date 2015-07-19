class profile::base {
  class { '::ntp':
    servers => hiera('ntp::servers'),
  }

  class { '::locales':
    default_locale => hiera('locales::default_locale'),
    locales        => hiera('locales::installed_locales'),
  }

  $packages = union(
    hiera('packages::base_packages'),
    hiera('packages::extra_packages')
  )

  package { $packages:
    ensure => present,
  }

  $users = merge(
    hiera('users::base_users'),
    hiera('users::extra_users')
  )

  each($users) |$name, $data| {
    user { $name:
      ensure  => 'present',
      uid     => $data['uid'],
      comment => $data['full_name'],
      shell   => $data['shell'],
      groups  => $data['groups'],
      require => Group[$data['groups']],
    }
  }

  $groups = merge(
    hiera('groups::base_groups'),
    hiera('groups::extra_groups')
  )

  each($groups) |$name, $data| {
    group { $name:
      ensure  => 'present',
      gid     => $data['gid'],
    }
  }
}
