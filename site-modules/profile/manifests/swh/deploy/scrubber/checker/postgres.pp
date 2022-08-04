# Deployment of the swh.scrubber's checker postgres service

class profile::swh::deploy::scrubber::checker::postgres {
  $sentry_dsn = lookup("swh::deploy::scrubber::sentry_dsn")
  $sentry_environment = lookup("swh::deploy::scrubber::sentry_environment")
  $sentry_swh_package = lookup("swh::deploy::scrubber::sentry_swh_package")

  $config_dir = lookup('swh::deploy::scrubber::checker::postgres::conf_directory')
  $user = lookup('swh::deploy::scrubber::checker::postgres::user')
  $group = lookup('swh::deploy::scrubber::checker::postgres::group')

  $object_types = lookup('swh::deploy::scrubber::checker::postgres::object_types')
  $ranges = lookup('swh::deploy::scrubber::checker::postgres::ranges')

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
      File[$config_file],
      ::Systemd::Unit_file[$systemd_slice_name],
      Package[$packages],
    ]
  }

  $config_per_dbs_to_scrub = lookup('swh::deploy::scrubber::checker::postgres::config_per_db')

  # As many services as there are dbs to scrub
  $config_per_dbs_to_scrub.each | $db_name, $cfg | {
    $config_file = "${config_dir}/${db_name}.yaml"
    $config_dict = $cfg['config']
    file {$config_file:
      ensure  => present,
      owner   => $user,
      group   => $group,
      mode    => '0640',
      content => inline_yaml($config_dict),
      require => File[$config_dir]
    }

    $object_types.each | $object_type | {
      $ranges.each | $range_index, $range | {
        $ranges_list = $range.split(':')
        $start_object = $ranges_list[0]
        $end_object = $ranges_list[1]
        $service_name = "${template_name}@${db_name}-${object_type}-${range_index}.service"

        $parameters_conf_name = "${service_name}.d/parameters.conf"
        # Template uses:
        # - $object_type
        # - $start_object
        # - $end_object
        # - $config_file
        ::systemd::dropin_file {$parameters_conf_name:
          ensure   => present,
          unit     => $service_name,
          filename => 'parameters.conf',
          content  => template("profile/swh/deploy/scrubber/parameters.conf.erb"),
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
    }
  }

  # clean up old resources
  $object_types.each | $object_type | {
    $ranges.each | $range_index, $range | {
      $old_svc_name = "${template_name}@${object_type}-${range_index}.service"
      $old_params_confname = "${old_svc_name}.d/parameters.conf"

      ::systemd::dropin_file {$old_params_confname:
        ensure   => absent,
        unit     => $old_svc_name,
        filename => 'parameters.conf',
      }

      service {$old_svc_name:
        ensure  => stopped,
        enable  => false,
      }
    }
  }
}
