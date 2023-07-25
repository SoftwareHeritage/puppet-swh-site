# Deployment of the swh.scrubber's checker postgres service

class profile::swh::deploy::scrubber::checker::postgres {
  $sentry_dsn = lookup("swh::deploy::scrubber::sentry_dsn")
  $sentry_environment = lookup("swh::deploy::scrubber::sentry_environment")
  $sentry_swh_package = lookup("swh::deploy::scrubber::sentry_swh_package")

  $config_dir = lookup('swh::deploy::scrubber::checker::conf_directory')
  $user = lookup('swh::deploy::scrubber::checker::user')
  $group = lookup('swh::deploy::scrubber::checker::group')

  $packages = ['python3-swh.scrubber']
  ensure_packages($packages)

  file {$config_dir:
    ensure  => 'directory',
    owner   => $user,
    group   => $group,
    purge   => true,
    force   => true,
    recurse => true,
  }

  $systemd_slice_name = "swh-scrubber.slice"
  ::systemd::unit_file {$systemd_slice_name:
    ensure => 'present',
    source => "puppet:///modules/profile/swh/deploy/scrubber/${systemd_slice_name}",
  }

  $template_name = 'swh-scrubber-checker-postgres'
  $template_unit_name = "${template_name}@.service"
  # Template uses:
  # - $user
  # - $group
  # - $sentry_dsn
  # - $sentry_environment
  # - $sentry_swh_package
  ::systemd::unit_file {$template_unit_name:
    ensure  => present,
    content => template("profile/swh/deploy/scrubber/${template_unit_name}.erb"),
    enable  => false,
    require => [
      ::Systemd::Unit_file[$systemd_slice_name],
      Package[$packages],
    ]
  }

  $base_config = lookup('swh::deploy::scrubber::checker::base_config')
  $storage_configs = lookup('swh::deploy::scrubber::checker::storage::config_per_instance')
  $range_configs = lookup('swh::deploy::scrubber::checker::range_configs')

  # As many services as there are storage instances to scrub
  $storage_configs.each | $instance, $storage_cfg | {
    $config_file = "${config_dir}/storage_${instance}.yml"
    $config_dict = $base_config + {
      storage => $storage_cfg
    }
    file {$config_file:
      ensure  => present,
      owner   => $user,
      group   => $group,
      mode    => '0640',
      content => inline_yaml($config_dict),
      require => File[$config_dir]
    }

    $range_configs.each | $object_type, $range_config | {
      $num_scrubbers = $range_config['num_scrubbers']
      $num_partitions = 1 << $range_config['num_partitions_log2']

      Integer[0, $num_scrubbers - 1].each |$index| {
        $start_partition_id = $index * ($num_partitions / $num_scrubbers)

        if ($index != $num_scrubbers - 1) {
          $end_partition_id = ($index + 1) * ($num_partitions / $num_scrubbers)
        } else {
          $end_partition_id = $num_partitions
        }

        $service_name = "${template_name}@${instance}-${object_type}-${index}.service"

        $parameters_conf_name = "${service_name}.d/parameters.conf"
        # Template uses:
        # - $object_type
        # - $start_partition_id
        # - $end_partition_id
        # - $nb_partitions
        # - $config_file
        ::systemd::dropin_file {$parameters_conf_name:
          ensure   => present,
          unit     => $service_name,
          filename => 'parameters.conf',
          content  => template('profile/swh/deploy/scrubber/parameters.conf.erb'),
        }

        service {$service_name:
          ensure  => running,
          enable  => true,
          require => [
            ::Systemd::Unit_file[$template_unit_name],
            ::Systemd::Dropin_File[$parameters_conf_name],
          ],
        }
      }

      # Clean up leftovers if any (in case we change the numbers of scrubbers).
      Integer[$num_scrubbers, 8].each |$index| {
        $service_name = "${template_name}@${instance}-${object_type}-${index}.service"

        $parameters_conf_name = "${service_name}.d/parameters.conf"
        ::systemd::dropin_file {$parameters_conf_name:
          ensure   => absent,
          unit     => $service_name,
          filename => 'parameters.conf',
        }

        service {$service_name:
          ensure  => stopped,
          enable  => false,
        }
      }
    }
  }
}
