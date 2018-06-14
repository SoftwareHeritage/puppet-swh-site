# Unattended upgrades configuration
class profile::swh::apt_config::unattended_upgrades {
  $origins = lookup('swh::apt_config::unattended_upgraes::origins')

  class {'::unattended_upgrades':
    mail    => {
      to => 'root',
    },
    origins => $origins,
  }
}
