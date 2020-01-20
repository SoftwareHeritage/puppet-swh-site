# swh's end-to-end checks on the icinga master
class profile::icinga2::objects::e2e_checks {
  $checks_file = '/etc/icinga2/conf.d/e2e-checks.conf'

  $deposit_server = lookup('swh::deploy::deposit::e2e::server')
  $deposit_user = lookup('swh::deploy::deposit::e2e::user')
  $deposit_pass = lookup('swh::deploy::deposit::e2e::password')
  $deposit_poll_interval = lookup('swh::deploy::deposit::e2e::poll_interval')
  $deposit_archive = lookup('swh::deploy::deposit::e2e:archive')
  $deposit_metadata = lookup('swh::deploy::deposit::e2e:metadata')

  $packages = ["python3-swh.icingaplugins"]

  package {$packages:
    ensure => present
  }

  ::icinga2::object::checkcommand {'check_deposit':
    import        => ['plugin-check-command'],
    command       => [
      "/usr/bin/swh", "icinga_plugins", "check-deposit",
      "--server", "${deposit_server}",
      "--user", "${deposit_user}",
      "--password", "${deposit_pass}",
      "--collection", "${deposit_collection}",
      "--poll-interval", "${deposit_poll_interval}",
      "single",
      "--archive", "${deposit_archive}",
      "--metadata", "${deposit_metadata}",
    ],
    target        => $checks_file,
    require       => Package[$packages]
  }
}
