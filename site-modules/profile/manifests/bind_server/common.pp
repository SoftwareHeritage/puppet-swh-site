# Common resources between primary and secondary bind servers

class profile::bind_server::common {
  include ::profile::resolv_conf

  $forwarders = lookup('dns::forwarders')
  $zones = lookup('bind::zones')
  $default_zone_data = lookup('bind::zones::default_data')
  $clients = lookup('bind::clients')
  $update_key = lookup('bind::update_key')

  bind::key { $update_key:
    secret_bits => 512,
  }

  class { '::bind':
    forwarders => $forwarders,
    dnssec     => true,
  }

  Service['bind'] -> File['/etc/resolv.conf']

  bind::view { 'private':
    recursion     => true,
    zones         => keys($zones),
    match_clients => $clients,
  }

  each($zones) |$zone, $data| {
    $merged_data = merge($default_zone_data, $data)

    if $merged_data['zone_type'] == 'master' {
      $allow_updates = union(
        any2array($merged_data['allow_updates']),
        ["key ${update_key}"],
      )
      $masters = undef

      resource_record { "${zone}/NS":
        type    => 'NS',
        record  => $zone,
        data    => $merged_data['ns_records'],
        keyfile => "/etc/bind/keys/${profile::bind_server::common::update_key}",
      }

    } else {
      $allow_updates = undef
      $masters = $merged_data['masters']
    }

    bind::zone { $zone:
      zone_type       => $merged_data['zone_type'],
      domain          => $merged_data['domain'],
      dynamic         => $merged_data['dynamic'],
      masters         => $masters,
      transfer_source => $merged_data['transfer_source'],
      allow_updates   => $allow_updates,
      update_policies => $merged_data['update_policies'],
      allow_transfers => $merged_data['allow_transfers'],
      dnssec          => $merged_data['dnssec'],
      key_directory   => $merged_data['key_directory'],
      ns_notify       => $merged_data['ns_notify'],
      also_notify     => $merged_data['also_notify'],
      allow_notify    => $merged_data['allow_notify'],
      forwarders      => $merged_data['forwarders'],
      forward         => $merged_data['forward'],
      source          => $merged_data['source'],
    }
  }
}
