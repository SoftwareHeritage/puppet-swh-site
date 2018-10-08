# Primary DNS server: the difference between this and a secondary is the
# presence of resource_records

class profile::bind_server::primary {
  include ::profile::bind_server::common

  $zones = lookup('bind::zones')
  $zone_names = keys($zones)
  $resource_records = lookup('bind::resource_records')
  $default_rr_data = lookup('bind::resource_records::default_data')

  each($resource_records) |$rr, $data| {
    $merged_data = merge($default_rr_data, $data)
    resource_record { $rr:
      type    => $merged_data['type'],
      record  => $merged_data['record'],
      data    => $merged_data['data'],
      keyfile => "/etc/bind/keys/${profile::bind_server::common::update_key}",
    }

    # Generate PTR record from A record
    if $merged_data['type'] == 'A' {
      $ptr = reverse_ipv4($merged_data['data'])
      $ptr_domain = join(values_at(split($ptr, '[.]'), '1-5'), '.')
      if member($zone_names, $ptr_domain) {
        resource_record { "${rr}+PTR":
          type    => 'PTR',
          record  => $ptr,
          data    => "${merged_data['record']}.",
          keyfile => "/etc/bind/keys/${profile::bind_server::common::update_key}",
        }
      }
    }
  }

  Resource_Record <<| |>>

  Bind::Zone <| |> -> Resource_Record <| |>
}
