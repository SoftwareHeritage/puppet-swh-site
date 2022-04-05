# Deployment for maven index exporter
class profile::maven_index_exporter {
  $user = 'root'
  $group = 'root'

  $publish_path = '/var/www/maven_index_exporter'

  $base_dir = "/srv/softwareheritage/maven-index-exporter/"
  $docker_image = lookup('maven_index_exporter::image::name')
  $docker_image_version = lookup('maven_index_exporter::image::version')
  $mvn_repositories = lookup('maven_index_exporter::repositories')

  # Create the base directory
  file { $base_dir:
    ensure  => directory,
    recurse => true,
    owner   => $user,
    group   => 'root',
  }
  $template_name = 'maven_index_exporter'
  $template_path = "profile/${template_name}"

  $script_name = "run_maven_index_exporter.sh"
  # Template use:
  # - $base_dir
  # - $publish_path
  # - $docker_image
  # - $docker_image_version
  file { "/usr/local/bin/${script_name}":
    ensure  => present,
    content => template("${template_path}/${script_name}.erb"),
    owner   => $user,
    group   => 'root',
    mode    => '0744'
  }

  # Install the publish path
  file { $publish_path:
    ensure  => directory,
    owner   => $user,
    group   => 'root',
    recurse => true,
  }

  # Service declaration

  $systemd_basename = "${template_name}@"
  $systemd_timer = "${systemd_basename}.timer"
  $systemd_service = "${systemd_basename}.service"

  # Declare: maven_index_exporter@.service and maven_index_exporter@.timer

  # Timer and service declaration
  # timer template uses:
  # - $template_name
  # Service template uses:
  # - $user
  # - $group
  ::systemd::timer { $systemd_timer:
    timer_content    => template("${template_path}/${systemd_timer}.erb"),
    service_content  => template("${template_path}/${systemd_service}.erb"),
    enable           => true,
  }

  $systemd_slice_name = "${template_name}.slice"
  ::systemd::unit_file {$systemd_slice_name:
    ensure => 'present',
    source => "puppet:///modules/profile/${template_name}/${systemd_slice_name}",
  }

  # Iterate over the maven repositories to extract index out of
  # and install configuration
  $mvn_repositories.each | $mvn_repo_name, $mvn_repo_url | {
    # systemd service declaration per maven repository
    $service_basename = "${template_name}@${mvn_repo_name}"
    $service_name = "${service_basename}.service"
    # Template use:
    # - $mvn_repo_url
    ::systemd::dropin_file {"${service_name}.d/parameters.conf":
      ensure   => present,
      unit     => $service_name,
      filename => 'parameters.conf',
      content  => template("${template_path}/parameters.conf.erb"),
    }

    ::systemd::unit_file {$service_name:
      ensure => present,
      enable => true,
    }
    $service_timer = "${service_basename}.timer"
    ::systemd::timer {$service_timer:
      ensure => present,
      enable => true,
      active => true,
    }
  }
}
