# Icinga2 configuration
class profile::icinga2 {
  $icinga2_role = lookup('icinga2::role')

  include profile::icinga2::apt_config

  case $icinga2_role {
    'agent':  { include profile::icinga2::agent }
    'master': { include profile::icinga2::master }
    default:  { fail("Unknown icinga2::role: ${icinga2_role}") }
  }
}
