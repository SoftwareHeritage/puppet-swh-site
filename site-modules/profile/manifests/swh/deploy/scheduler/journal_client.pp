# Deployment of the swh.search.journal_client
class profile::swh::deploy::scheduler::journal_client {
  include ::profile::swh::deploy::base_scheduler
  include ::profile::swh::deploy::journal

  $config_file = lookup('swh::deploy::scheduler::journal_client::config_file')
  $config = lookup('swh::deploy::scheduler::journal_client::config')

  $user = lookup('swh::deploy::scheduler::journal_client::user')
  $group = lookup('swh::deploy::scheduler::journal_client::group')

  $service_name = 'swh-scheduler-journal-client'
  $unit_name = "${service_name}.service"

  file {$config_file:
    ensure  => present,
    owner   => 'root',
    group   => $group,
    mode    => '0640',
    content => inline_template("<%= @config.to_yaml %>\n"),
    notify  => Service[$service_name],
  }

  # Template uses variables
  #  - $user
  #  - $group
  #
  ::systemd::unit_file {$unit_name:
    ensure  => present,
    content => template("profile/swh/deploy/journal/${unit_name}.erb"),
  } ~> service {$service_name:
    ensure => running,
    enable => true,
  }

  @@::icinga2::object::service {"check_scheduler_journal_client_${::fqdn}":
    import           => ['generic-service'],
    name             => "Check swh scheduler journal client service ${::fqdn}",
    check_command    => "check_systemd",
    host_name        => $::fqdn,
    command_endpoint => $::fqdn,
    vars             => {
      check_systemd_unit => $unit_name,
    },
    target           => '/etc/icinga2/zones.d/master/exported-checks.conf',
    tag              => 'icinga2::exported',
  }

}
