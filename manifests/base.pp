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

  $users.each |$name, $data| {
    user { $name:
      ensure  => 'present',
      uid     => $data['uid'],
      comment => $data['full_name'],
      shell   => $data['shell'],
    }
  }

  $groups = merge(
    hiera('groups::base_groups'),
    hiers('groups::extra_groups')
  )

  $groups.each |$name, $data| {
    group { $name:
      ensure  => 'present',
      gid     => $data['gid'],
      members => $data['members'],
    }
  }
}
