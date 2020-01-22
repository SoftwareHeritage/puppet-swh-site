# swh's end-to-end checks on the icinga master
class profile::icinga2::objects::e2e_checks {
  $checks_file = '/etc/icinga2/conf.d/e2e-checks.conf'

  $deposit_server = lookup('swh::deploy::deposit::e2e::server')
  $deposit_user = lookup('swh::deploy::deposit::e2e::user')
  $deposit_pass = lookup('swh::deploy::deposit::e2e::password')
  $deposit_collection = lookup('swh::deploy::deposit::e2e::collection')
  $deposit_poll_interval = lookup('swh::deploy::deposit::e2e::poll_interval')
  $deposit_archive = lookup('swh::deploy::deposit::e2e:archive')
  $deposit_metadata = lookup('swh::deploy::deposit::e2e:metadata')

  $server_vault = lookup('swh::deploy::vault::e2e::storage')
  $server_webapp = lookup('swh::deploy::vault::e2e::webapp')

  $packages = ["python3-swh.icingaplugins"]

  package {$packages:
    ensure => present
  }

  ::icinga2::object::checkcommand {'check-deposit-cmd':
    import        => ['plugin-check-command'],
    command       => [
      "/usr/bin/swh", "icinga_plugins", "check-deposit",
      "--server", "${deposit_server}",
      "--username", "${deposit_user}",
      "--password", "${deposit_pass}",
      "--collection", "${deposit_collection}",
      "--poll-interval", "${deposit_poll_interval}",
      "single",
      "--archive", "${deposit_archive}",
      "--metadata", "${deposit_metadata}",
    ],
    # XXX: Should probably be split into usual commands with arguments
    # arguments => ...
    target        => $checks_file,
    require       => Package[$packages]
  }

  ::icinga2::object::checkcommand {'check-vault-cmd':
    import        => ['plugin-check-command'],
    command       => [
      "/usr/bin/swh", "icinga_plugins", "check-vault",
      "--swh-storage-url", "${server_vault}",
      "--swh-web-url", "${server_webapp}",
      "directory"
    ],
    target        => $checks_file,
    require       => Package[$packages]
  }
}
