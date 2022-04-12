# Deployment for maven index exporter
class profile::maven_index_exporter {
  $user = 'root'
  $group = 'root'

  $vhost_name = lookup('maven_index_exporter::vhost::name')
  $vhost_ssl_protocol = lookup('maven_index_exporter::vhost::ssl_protocol')
  $vhost_ssl_honorcipherorder = lookup('maven_index_exporter::vhost::ssl_honorcipherorder')
  $vhost_ssl_cipher = lookup('maven_index_exporter::vhost::ssl_cipher')
  $vhost_hsts_header = lookup('maven_index_exporter::vhost::hsts_header')

  $publish_path = '/var/www/maven_index_exporter'
  $icinga_checks_file = lookup('icinga2::exported_checks::filename')

  $base_dir = "/srv/softwareheritage/maven-index-exporter"
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

  # Vhost declaration

  ::apache::vhost {"${vhost_name}_non-ssl":
    servername      => $vhost_name,
    port            => '80',
    docroot         => $publish_path,
    manage_docroot  => false,
    redirect_status => 'permanent',
    redirect_dest   => "https://${vhost_name}/",
  }

  ::profile::letsencrypt::certificate {$vhost_name:}

  $cert_paths = ::profile::letsencrypt::certificate_paths($vhost_name)
  ::apache::vhost {"${vhost_name}_ssl":
    servername           => $vhost_name,
    port                 => '443',
    ssl                  => true,
    ssl_protocol         => $vhost_ssl_protocol,
    ssl_honorcipherorder => $vhost_ssl_honorcipherorder,
    ssl_cipher           => $vhost_ssl_cipher,
    ssl_cert             => $cert_paths['cert'],
    ssl_chain            => $cert_paths['chain'],
    ssl_key              => $cert_paths['privkey'],
    headers              => [$vhost_hsts_header],
    docroot              => $publish_path,
    manage_docroot       => false,
    require              => [
      File[$cert_paths['cert']],
      File[$cert_paths['chain']],
      File[$cert_paths['privkey']],
    ],
  }

  File[$cert_paths['cert'], $cert_paths['chain'], $cert_paths['privkey']] ~> Class['Apache::Service']

  @@::icinga2::object::service {"Maven Index Exporter report http redirect on ${::fqdn}":
    service_name  => 'maven index exporter report http redirect',
    import        => ['generic-service'],
    host_name     => $::fqdn,
    check_command => 'http',
    vars          => {
      http_address => $vhost_name,
      http_vhost   => $vhost_name,
      http_uri     => '/',
    },
    target        => $icinga_checks_file,
    tag           => 'icinga2::exported',
  }

  @@::icinga2::object::service {"Maven Index Exporter report https on ${::fqdn}":
    service_name  => 'maven index exporter report https',
    import        => ['generic-service'],
    host_name     => $::fqdn,
    check_command => 'http',
    vars          => {
      http_address    => $vhost_name,
      http_vhost      => $vhost_name,
      http_ssl        => true,
      http_sni        => true,
      http_uri        => '/',
      http_onredirect => sticky
    },
    target        => $icinga_checks_file,
    tag           => 'icinga2::exported',
  }

  @@::icinga2::object::service {"Maven Index Exporter report https certificate ${::fqdn}":
    service_name  => 'maven index exporter report https certificate',
    import        => ['generic-service'],
    host_name     => $::fqdn,
    check_command => 'http',
    vars          => {
      http_address     => $vhost_name,
      http_vhost       => $vhost_name,
      http_ssl         => true,
      http_sni         => true,
      http_certificate => 25,
    },
    target        => $icinga_checks_file,
    tag           => 'icinga2::exported',
  }

}
