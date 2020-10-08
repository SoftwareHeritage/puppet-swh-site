class profile::keycloak::resources {
  $realms = lookup({
    name          => 'keycloak::resources::realms',
    value_type    => Hash,
    merge         => {
      strategy        => 'deep',
      knockout_prefix => '--',
    },
    default_value => {},
  })

  $realm_common_settings = lookup({
    name          => 'keycloak::resources::realms::common_settings',
    value_type    => Hash,
    merge         => {
      strategy        => 'deep',
      knockout_prefix => '--',
    },
    default_value => {},
  })

  $client_common_settings = lookup({
    name          => 'keycloak::resources::clients::common_settings',
    value_type    => Hash,
    merge         => {
      strategy        => 'deep',
      knockout_prefix => '--',
    },
    default_value => {},
  })

  $realms.each |$realm_name, $realm_data| {
    $_local_realm_settings = pick($realm_data['settings'], {})
    $_full_realm_settings = deep_merge($realm_common_settings, $_local_realm_settings)

    keycloak_realm {$realm_name:
      ensure => present,
      *      => $_full_realm_settings,
    }

    $flows = pick($realm_data['flows'], [])

    $flows.each |$flow_data| {
      $flow_alias = "${flow_data['name']}-${realm_name}"
      $flow_id = fqdn_uuid("${flow_data['name']}-${realm_name}")
      keycloak_flow {"${flow_data['name']} on ${realm_name}" :
        ensure       => present,
        alias        => $flow_alias,
        id           => $flow_id,
        description  => $flow_data['description'],
      }

      $flow_executions = pick($flow_data['executions'], {})

      $idx = 0
      $flow_executions.each |$flow_execution_name, $flow_execution_data| {
        $flow_execution_id = fqdn_uuid("${flow_execution_name}-${realm_name}")
        keycloak_flow_execution {"${flow_execution_name} under ${flow_alias} on ${realm_name}" :
          ensure => present,
          alias  => "${flow_execution_name}-${realm_name}",
          id     => $flow_execution_id,
          index  => $idx,
          *      => $flow_execution_data,
        }
        $idx = $idx + 1
      }
    }

    $clients = pick($realm_data['clients'], {})
    $realm_client_common_settings = deep_merge($client_common_settings,
                                               pick($realm_data['client_settings'], {}))

    $clients.each |$client_name, $client_data| {
      $_local_client_settings = pick($client_data['settings'], {})
      $_full_client_settings = deep_merge($realm_client_common_settings, $_local_client_settings)

      $client_id = fqdn_uuid("${realm_name}.${client_name}")

      keycloak_client {"${client_name} on ${realm_name}":
        ensure => present,
        id => $client_id,
        *  => $_full_client_settings,
      }

      $protocol_mappers = pick($client_data['protocol_mappers'], [])

      $protocol_mappers.each | Hash $protocol_mapper_data | {
        $_pm_data = Hash($protocol_mapper_data.map |$key, $value| {
          [$key, $value ? {'__client_id__' => $client_name, default => $value}]
        })

        $protocol_mapper_name = $protocol_mapper_data['resource_name']
        $protocol_mapper_id = fqdn_uuid("${realm_name}.${client_name}.${protocol_mapper_name}")

        keycloak_client_protocol_mapper {"${protocol_mapper_name} for ${client_id} on ${realm_name}":
          ensure => present,
          id     => $protocol_mapper_id,
          *      => $_pm_data,
        }
      }
    }
  }
}
