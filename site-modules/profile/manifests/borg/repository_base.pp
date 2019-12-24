# Base, shared configuration for borg repositories

class profile::borg::repository_base {
  include profile::borg::packages

  $user = lookup('borg::repository_user')
  $group = lookup('borg::repository_group')

  $base_path = lookup('borg::base_path')
  $repository_path = lookup('borg::repository_path')
  $ssh_path = "${base_path}/.ssh"

  group {$group:
    ensure => 'present',
    system => true,
  }

  user {$user:
    ensure => 'present',
    system => true,
    gid    => $group,
    home   => $base_path,
  }

  file {[$base_path, $repository_path, $ssh_path]:
    ensure => 'directory',
    owner  => $user,
    group  => $group,
    mode   => '0600',
  }

  $authorized_keys = "${ssh_path}/authorized_keys"
  concat {$authorized_keys:
    ensure => present,
    owner  => $user,
    group  => $group,
    mode   => '0600',
  }
}
