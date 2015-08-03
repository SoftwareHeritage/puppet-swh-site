class profile::bind_server {

  $forwarders = hiera('bind::forwarders')
  $zones = hiera('bind::zones')
  $default_zone_data = hiera('bind::zones::default_data')
  $clients = hiera('bind::clients')
  $resource_records = hiera('bind::resource_records')
  $default_rr_data = hiera('bind::resource_records::default_data')
  $zone_names = keys($zones)

  class { '::bind':
    forwarders => $forwarders,
    dnssec     => true,
  }

  bind::view { 'private':
    recursion     => true,
    zones         => $zone_names,
    match_clients => $clients,
  }

  bind::key { 'local-update':
    secret_bits => 512,
  }

  each($zones) |$zone, $data| {
    $merged_data = merge($default_zone_data, $data)
    bind::zone { $zone:
      zone_type       => $merged_data['zone_type'],
      domain          => $merged_data['domain'],
      dynamic         => $merged_data['dynamic'],
      masters         => $merged_data['masters'],
      transfer_source => $merged_data['transfer_source'],
      allow_updates   => union(
        any2array($merged_data['allow_updates']),
        ['key local-update'],
      ),
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
      type    => $merged_data['type'],
      record  => $merged_data['record'],
      data    => $merged_data['data'],
      keyfile => '/etc/bind/keys/local-update'
    }

    # Generate PTR record from A record
    if $merged_data['type'] == 'A' {
      $ptr = reverse_ipv4($merged_data['data'])
      $ptr_domain = join(values_at(split($ptr, '[.]'), '1-5'), '.')
      if member($zone_names, $ptr_domain) {
        resource_record { "${rr}+PTR":
          type    => "PTR",
          record  => $ptr,
          data    => "${merged_data['record']}.",
          keyfile => '/etc/bind/keys/local-update',
        }
      }
    }
  }

  Resource_Record <<| |>>
}
