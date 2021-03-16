# swh deposit end-to-end checks on the icinga master
define profile::icinga2::objects::e2e_checks_deposit (
  String $deposit_server,
  String $deposit_user,
  String $deposit_pass,
  String $deposit_collection,
  Integer $deposit_poll_interval,
  String $deposit_archive,
  String $deposit_metadata,
  String $environment,
) {
  include ::profile::icinga2::objects::e2e_checks_base

  $check_command = "${environment}-check-deposit-cmd"

  ::icinga2::object::checkcommand {$check_command:
    import  => ['plugin-check-command'],
    command => [
      '/usr/bin/swh', 'icinga_plugins',
      '-w', '600',
      'check-deposit',
      '--server', $deposit_server,
      '--username', $deposit_user,
      '--password', $deposit_pass,
      '--collection', $deposit_collection,
      '--poll-interval', $deposit_poll_interval,
      'single',
      '--archive', $deposit_archive,
      '--metadata', $deposit_metadata,
    ],
    # XXX: Should probably be split into usual commands with arguments
    # arguments => ...
    timeout => 900,
    target  => $::profile::icinga2::objects::e2e_checks_base::check_file,
    require => Package[$::profile::icinga2::objects::e2e_checks_base::packages]
  }

  ::icinga2::object::service {"${environment}-check-deposit":
    import           => ['generic-service-check-e2e'],
    service_name     => "${environment} Check deposit end-to-end",
    check_command    => $check_command,
    target           => "/etc/icinga2/zones.d/${zonename}/${::fqdn}.conf",
    host_name        => "${::fqdn}",
  }

}
