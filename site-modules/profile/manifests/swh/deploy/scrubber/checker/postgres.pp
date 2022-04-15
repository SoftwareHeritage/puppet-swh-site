# Deployment of the swh.scrubber's checker postgres service

class profile::swh::deploy::scrubber::checker::postgres {
  $sentry_dsn = lookup("swh::deploy::scrubber::sentry_dsn")
  $sentry_environment = lookup("swh::deploy::scrubber::sentry_environment")
  $sentry_swh_package = lookup("swh::deploy::scrubber::sentry_swh_package")

  $config_dir = lookup('swh::deploy::scrubber::checker::postgres::conf_directory')
  $config_file = lookup('swh::deploy::scrubber::checker::postgres::conf_file')
  $config_dict = lookup('swh::deploy::scrubber::checker::postgres::config')
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
  }

  file {$config_file:
    ensure  => present,
    owner   => $user,
    group   => $group,
    mode    => '0640',
    content => inline_template("<%= @config_dict.to_yaml %>\n"),
    require => File[$config_dir]
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
  # - $config_file
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

  $object_types.each | $object_type | {
    $ranges.each | $range_index, $range | {
      $ranges_list = $range.split(':')
      $start_object = $ranges_list[0]
      $end_object = $ranges_list[1]
      $service_name = "${template_name}@${object_type}-${range_index}.service"

      $parameters_conf_name = "${service_name}.d/parameters.conf"
      # Template uses:
      # - $object_type
      # - $start_object
      # - $end_object
      ::systemd::dropin_file {$parameters_conf_name:
        ensure   => present,
        unit     => $service_name,
        filename => 'parameters.conf',
        content  => template("profile/swh/deploy/scrubber/parameters.conf.erb"),
      }

      service {$service_name:
        ensure  => running,
        enable  => false,
        require => [
          ::Systemd::Unit_file[$template_unit_name],
          ::Systemd::Dropin_File[$parameters_conf_name],
        ],
      }
    }
  }
}
