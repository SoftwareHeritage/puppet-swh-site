# Icinga2 configuration
class profile::icinga2 {
  $icinga2_role = lookup('icinga2::role')

  include profile::icinga2::apt_config

  $user = 'nagios'
  $group = 'nagios'
  $additional_groups = [
    'puppet',  # needed to grant access to puppet directories to check its status
  ]

  group {$group:
    system => true,
  }
  -> user {$user:
    system => true,
    gid    => $group,
    shell  => '/usr/sbin/nologin',
    home   => '/var/lib/nagios',
    groups => $additional_groups
  }

  case $icinga2_role {
    'agent':  { include profile::icinga2::agent }
    'master': { include profile::icinga2::master }
    default:  { fail("Unknown icinga2::role: ${icinga2_role}") }
  }
}
