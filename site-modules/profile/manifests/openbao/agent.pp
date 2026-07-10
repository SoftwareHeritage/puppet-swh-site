define profile::openbao::agent (
  String $instance_name = $title,
  String $auto_auth_method = "approle",
  Optional[String] $auto_auth_mount_path = undef,
  Hash[String, Variant[String, Boolean]] $auto_auth_config = {},
  Array[Hash[String, Any]] $sinks = [],
  String $owner = 'root',
  String $group = 'root',
) {
  include profile::openbao::agent_common

  $config_path = "${profile::openbao::agent_common::config_dir}/${instance_name}.json"

  $vault_address = lookup('openbao::address')

  $base_auto_auth_config = {
    type   => $auto_auth_method,
    config => $auto_auth_config,
  }

  if $auto_auth_mount_path {
    $full_auto_auth_config = {mount_path => $auto_auth_mount_path} + $base_auto_auth_config
  } else {
    $full_auto_auth_config = $base_auto_auth_config
  }

  $sinks_config = $sinks.map |Hash $sink| { { sink => $sink } }

  $config = {
    vault => {
      address => $vault_address,
    },
    auto_auth => {
      method => [$full_auto_auth_config],
    },
    sinks => $sinks_config,
  }
  
  file {$config_path:
    ensure  => present,
    content => stdlib::to_json_pretty($config),
    owner   => $owner,
    group   => $group,
  }

  $unit_name = "openbao-agent@${instance_name}.service"
  systemd::manage_dropin {"${unit_name}/parameters.conf":
    ensure        => present,
    unit          => $unit_name,
    filename      => "parameters.conf",
    service_entry => {
      'User'  => $owner,
      'Group' => $group,
    }
  }
  -> service {$unit_name:
    enable => true,
    ensure => 'started',
  }
}
