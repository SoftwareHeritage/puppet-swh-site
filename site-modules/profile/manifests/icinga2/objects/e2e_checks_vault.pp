# swh vault end-to-end checks on the icinga master
define profile::icinga2::objects::e2e_checks_vault (
  String $server_vault,
  String $server_webapp,
  String $environment,
) {
  include ::profile::icinga2::objects::e2e_checks_base

  $check_command = "${environment}-check-vault-cmd"
  $zonename = lookup('icinga2::master::zonename')

  ::icinga2::object::checkcommand {$check_command:
    import  => ['plugin-check-command'],
    command => [
      '/usr/bin/swh', 'icinga_plugins', 'check-vault',
      '--swh-storage-url', $server_vault,
      '--swh-web-url', $server_webapp,
      'directory'
    ],
    target  => $::profile::icinga2::objects::e2e_checks_base::check_file,
    require => Package[$::profile::icinga2::objects::e2e_checks_base::packages],
  }

  ::icinga2::object::service {"${environment}-check-vault":
    import           => ['generic-service-check-e2e'],
    service_name     => "${environment} Check vault end-to-end",
    check_command    => $check_command,
    target           => "/etc/icinga2/zones.d/${zonename}/${::fqdn}.conf",
    host_name        => "${::fqdn}",
  }

}
