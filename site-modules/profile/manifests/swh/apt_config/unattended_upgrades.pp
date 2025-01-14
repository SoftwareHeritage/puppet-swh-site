# Unattended upgrades configuration
class profile::swh::apt_config::unattended_upgrades {
  $origins = lookup('swh::apt_config::unattended_upgrades::origins')

  class {'::unattended_upgrades':
    origins                => $origins,
    remove_new_unused_deps => false,
    mail                   => {
      to => 'root',
    },
    auto                   => {
      remove => false,
    },
  }
}
