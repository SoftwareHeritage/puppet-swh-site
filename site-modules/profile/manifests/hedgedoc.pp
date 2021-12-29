# deploy a hedgedoc instance
class profile::hedgedoc {
  include profile::hedgedoc::apt_config
  include profile::hedgedoc::user

  $user = $::profile::hedgedoc::user::user
  $group = $::profile::hedgedoc::user::group

  # ---- install
  $version = lookup('hedgedoc::release::version')
  $archive_url = "https://github.com/hedgedoc/hedgedoc/releases/download/${version}/hedgedoc-${version}.tar.gz"
  $archive_digest = lookup('hedgedoc::release::digest')
  $archive_digest_type = lookup('hedgedoc::release::digest_type')

  $install_basepath = "/opt/hedgedoc"
  $install_dir = "${install_basepath}/${version}"
  $install_db_dump = "${install_basepath}/db-backup_pre-${version}.sql.gz"
  $install_flag = "${install_dir}/setup_done"

  $uploads_dir = "${install_basepath}/uploads"

  $yarn_cachedir = "/var/cache/hedgedoc-yarn"

  $archive_path = "${install_basepath}/${version}.tar.gz"

  $current_symlink = "${install_basepath}/current"

  $service_name = "hedgedoc"
  $unit_name = "${service_name}.service"

  file { [$install_basepath, $install_dir, $uploads_dir]:
    ensure  => 'directory',
    owner   => $user,
    group   => $group,
    mode    => '0644',
  }

  file { $yarn_cachedir:
    ensure  => 'directory',
    owner   => $user,
    group   => $group,
    mode    => '0600',
  }

  archive { 'hedgedoc':
    path            => $archive_path,
    extract         => true,
    extract_command => 'tar xzf %s --strip-components=1 --no-same-owner --no-same-permissions',
    source          => $archive_url,
    extract_path    => $install_dir,
    checksum        => $archive_digest,
    checksum_type   => $archive_digest_type,
    creates         => "${install_dir}/bin/setup",
    cleanup         => true,
    user            => $user,
    group           => $group,
    require         => File[$install_dir],
    notify          => Exec['hedgedoc-setup'],
  }

  # ---- configuration
  $db_host = lookup('hedgedoc::db::host')
  $db_name = lookup('hedgedoc::db::database')
  $db_user = lookup('hedgedoc::db::username')
  $db_password = lookup('swh::deploy::hedgedoc::db::password')
  $db_port = lookup('swh::postgresql::port')
  $db_url = "postgres://${db_user}:${db_password}@${db_host}:${db_port}/${db_name}"

  $sequelizerc_path = "${install_dir}/.sequelizerc"

  file {$sequelizerc_path:
    ensure  => present,
    owner   => $user,
    group   => $group,
    mode    => '0644',
    content => template("profile/hedgedoc/sequelizerc.erb"),
    notify  => Service[$service_name],
  }

  $base_url = lookup('swh::deploy::hedgedoc::base_url')

  $runtime_environment = lookup('hedgedoc::runtime_environment')
  $log_level = lookup('hedgedoc::log_level')

  $session_secret = lookup('hedgedoc::session_secret')

  $allow_anonymous = lookup('hedgedoc::allow_anonymous')
  $allow_anonymous_edits = lookup('hedgedoc::allow_anonymous_edits')
  $allow_email = lookup('hedgedoc::allow_email')
  $allow_email_register = lookup('hedgedoc::allow_email_register')

  $enable_keycloak = lookup('hedgedoc::enable_keycloak', Boolean, 'first', false)
  $keycloak_domain = lookup('hedgedoc::keycloak::domain')
  $keycloak_provider_name = lookup('hedgedoc::keycloak::provider_name')
  $keycloak_realm = lookup('hedgedoc::keycloak::realm')
  $keycloak_client_id = lookup('hedgedoc::keycloak::client::id')
  $keycloak_client_secret = lookup('hedgedoc::keycloak::client::secret')

  $config_json_path = "${install_dir}/config.json"

  file {$config_json_path:
    ensure  => present,
    owner   => $user,
    group   => $group,
    # Contains credentials
    mode    => '0600',
    content => template("profile/hedgedoc/config.json.erb"),
    notify  => Service[$service_name],
  }

  exec {'hedgedoc-dump-db':
    command     => "pg_dump ${db_name} | gzip -9 > ${install_db_dump}",
    path        => ["/bin", "/usr/bin"],
    environment => [
      "PGHOST=${db_host}",
      "PGUSER=${db_user}",
      "PGPORT=${db_port}",
      "PGPASSWORD=${db_password}",
    ],
    creates     => $install_db_dump,
    user        => $user,
    umask       => '0066',
    require     => [
      Postgresql::Server::Db[$db_name],
    ],
  }

  -> exec {'hedgedoc-setup':
    command     => "${install_dir}/bin/setup && touch ${install_flag}",
    cwd         => $install_dir,
    require     => [
      Postgresql::Server::Db[$db_name],
      File[$config_json_path],
      File[$sequelizerc_path],
    ],
    environment => [
      "YARN_CACHE_FOLDER=${yarn_cachedir}",
    ],
    creates     => $install_flag,
    user        => $user,
  }

  -> file {$current_symlink:
    ensure      => 'link',
    target      => $install_dir,
    notify      => Service[$service_name],
  }

  -> systemd::unit_file {$unit_name:
    ensure  => present,
    content => template('profile/hedgedoc/hedgedoc.service.erb'),
  }

  -> service {$service_name:
    ensure  => 'running',
    enable  => true,
    require => [
      Class['profile::hedgedoc::apt_config'],
    ],
  }

  profile::prometheus::export_scrape_config {"hedgedoc_${base_url}":
    job          => 'hedgedoc',
    target       => "${base_url}:443",
    scheme       => 'https',
    metrics_path => '/metrics',
  }
}
