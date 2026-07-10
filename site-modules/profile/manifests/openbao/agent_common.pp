class profile::openbao::agent_common {
  include profile::openbao::install

  $config_dir = "/etc/openbao-agent"

  file {$config_dir:
    ensure => directory,
    owner  => "root",
    group  => "root",
    mode   => "0755",
  }

  # systemd service template
  
}
