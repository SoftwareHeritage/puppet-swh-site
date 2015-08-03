class profile::bind {

  $forwarders = hiera('bind::forwarders')
  $zones = hiera('bind::zones')
  $default_zone_data = hiera('bind::zones::default_data')
  $clients = hiera('bind::clients')
  $resource_records = hiera('bind::resource_records')
  $default_rr_data = hiera('bind::resource_records::default_data')

  class { '::bind':
    forwarders => $forwarders,
    dnssec     => true,
  }

  bind::view { 'private':
    recursion     => true,
    zones         => keys($zones),
    match_clients => $clients,
  }

  each($zones) |$zone, $data| {
    $merged_data = merge($default_zone_data, $data)
    bind::zone { $zone:
      zone_type       => $merged_data['zone_type'],
      domain          => $merged_data['domain'],
      dynamic         => $merged_data['dynamic'],
      masters         => $merged_data['masters'],
      transfer_source => $merged_data['transfer_source'],
      allow_updates   => $merged_data['allow_updates'],
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

  each($resource_records) |$rr, $data| {
    $merged_data = merge($default_rr_data, $data)
    resource_record { $rr:
      type   => $merged_data['type'],
      record => $merged_data['record'],
      data   => $merged_data['data'],
    }
  }

  Resource_Record <<| |>>
}
