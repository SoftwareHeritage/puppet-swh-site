# Configure a server to be the destination
# of a zfs snapshot synchronization
# This server will pull the snasphots from
# the sources
class profile::sanoid::sync_destination {

  $configuration = lookup('syncoid::configuration')

  $sources = $configuration["sources"]

  if $sources {
    include profile::sanoid::install

    $sources.each | $key, $config | {
      $source_host = $config['host']

      $ssh_key_name = $config['ssh_key']
      $ssh_key = lookup("syncoid::ssh_key::${ssh_key_name}")
      $authorized_key = lookup("syncoid::public_keys::${ssh_key_name}")
      $ssh_key_type = $authorized_key["type"]
      # computing a substring of ssh_key_type to remove 'ssh-' of the name
      $ssh_key_filename = "/root/.ssh/id_${ssh_key_type[4,255]}.syncoid_${ssh_key_name}"

      ensure_resource( 'file', $ssh_key_filename, {
        ensure => present,
        owner => 'root',
        group => 'root',
        mode => '0600',
        content => $ssh_key,
      })

      @@::profile::sanoid::configure_sync_source { $::fqdn:
        user           => 'root',
        ssh_key_name   => "syncoid_${ssh_key_name}",
        ssh_key_type   => $ssh_key_type,
        authorized_key => $authorized_key['key'],
        tag            => $source_host,
      }

      # Create a timer and service for each dataset to sync
      $config['datasets'].each | $name, $props | {
        $dataset = $props['dataset']
        $target = pick($props['target'], $name)
        $destination = "${config['target_dataset_base']}/${key}/${target}"
        $service_basename = "syncoid-${key}-${name}"
        $source = "${source_host}:${dataset}"
        $delay = pick($props['delay'], lookup('syncoid::default_delay'))
        $sync_snap = pick($props['sync_snap'], true)

        if $sync_snap == false {
          $sync_options = ' --no-sync-snap'
        }
        # templates use:
        # - $ssh_key_filename
        # - $source
        # - $destination
        # - $delay
        # - $service_basename
        # - $sync_option
        ::systemd::timer { "${service_basename}.timer":
          timer_content   => template('profile/sanoid/syncoid.timer.erb'),
          service_content => template('profile/sanoid/syncoid.service.erb'),
          service_unit    => "${service_basename}.service",
          active          => true,
          enable          => true,
        }

      }
    }
  }


}
