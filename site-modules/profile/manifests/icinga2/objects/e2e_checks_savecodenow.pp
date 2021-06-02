# swh save_code_now end-to-end checks on the icinga master
define profile::icinga2::objects::e2e_checks_savecodenow (
  String $server_webapp,
  String $origin_name,
  String $origin_url,
  String $origin_type,
  String $environment,
) {
  include ::profile::icinga2::objects::e2e_checks_base

  $check_command_prefix = "${environment}-check-savecodenow"
  $zonename = lookup('icinga2::master::zonename')

  $check_command = "${check_command_prefix}-cmd-${origin_name}-${origin_type}"
  ::icinga2::object::checkcommand {$check_command:
    import  => ['plugin-check-command'],
    command => [
      '/usr/bin/swh', 'icinga_plugins',
      '--warning', '300',
      '--critical', '600',
      'check-savecodenow',
      '--swh-web-url', $server_webapp,
      'origin', $origin_url, '--visit-type', $origin_type
    ],
    target  => $::profile::icinga2::objects::e2e_checks_base::check_file,
    require => Package[$::profile::icinga2::objects::e2e_checks_base::packages],
    timeout => 600,
  }

  ::icinga2::object::service {"${check_command_prefix}-service-${origin_name}-${origin_type}":
    import           => ['generic-service-check-e2e'],
    service_name     => "${environment} Check save-code-now ${origin_name} with type ${origin_type} end-to-end",
    check_command    => $check_command,
    target           => "/etc/icinga2/zones.d/${zonename}/${::fqdn}.conf",
    host_name        => "${::fqdn}",
  }

}
