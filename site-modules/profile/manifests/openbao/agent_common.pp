class profile::openbao::agent_common {
  include profile::openbao::install

  $config_dir = "/etc/openbao-agent"

  file {$config_dir:
    ensure => directory,
    owner  => "root",
    group  => "root",
    mode   => "0755",
  }

  $openbao_bin = $::profile::openbao::install::openbao_bin
  
  systemd::manage_unit { 'openbao-agent@.service':
    enable        => false,
    active        => false,
    requires      => File[$openbao_bin],
    unit_entry    => {
      'Description' => 'OpenBAO agent for %i'
    },
    service_entry => {
      'Type'      => 'simple',
      'ExecStart' => "${openbao_bin} agent -config-file=/etc/openbao-agent/%i.json",
      'Restart'   => 'on-failure',
    },
  }
}
