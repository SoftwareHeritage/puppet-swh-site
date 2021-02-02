# deploy a hedgedoc instance
class profile::hedgedoc {

  $packages = [
    'npm', 'yarn', 'node-gyp'
  ]

  $keyid = lookup('yarn::apt_config::keyid')
  $key =   lookup('yarn::apt_config::key')

  # ---- configuration
  $user = lookup('hedgedoc::user')
  $group = lookup('hedgedoc::group')

  $base_url = lookup('swh::deploy::hedgedoc::base_url')

  $db_host = lookup('hedgedoc::db::host')
  $db_name = lookup('hedgedoc::db::database')
  $db_user = lookup('hedgedoc::db::username')
  $db_password = lookup('swh::deploy::hedgedoc::db::password')
  $db_port = lookup('swh::postgresql::port')
  $db_url = "postgres://${db_user}:${db_password}@${db_host}:${db_port}/${db_name}"

  $allow_anonymous = lookup('hedgedoc::allow_anonymous')
  $allow_anonymous_edits = lookup('hedgedoc::allow_anonymous_edits')
  $allow_email = lookup('hedgedoc::allow_email')
  $allow_email_register = lookup('hedgedoc::allow_email_register')

  $runtime_environment = lookup('hedgedoc::runtime_environment')
  $log_level = lookup('hedgedoc::log_level')

  # ---- install
  $version = lookup('hedgedoc::release::version')
  $archive_url = "https://github.com/hedgedoc/hedgedoc/releases/download/${version}/hedgedoc-${version}.tar.gz"
  $archive_digest = lookup('hedgedoc::release::digest')
  $archive_digest_type = lookup('hedgedoc::release::digest_type')
  $archive_path = "/tmp/hedgedoc-${version}.tar.gz"
  $root_install_path = "/opt"
  $install_path = "${root_install_path}/hedgedoc"
  $upgrade_flag_path = "${install_path}/hedgedoc-${version}-upgrade"

  $sequelizerc_config_sequelizerc_path = "${install_path}/.sequelizerc"
  $sequelizerc_config_json_path = "${install_path}/config.json"

  $service_name = "hedgedoc"
  $unit_name = "${service_name}.service"

  apt::source { 'yarn':
    location => "https://dl.yarnpkg.com/debian/",
    release  => 'stable',
    repos    => 'main',
    key      => {
      id      => $keyid,
      content => $key,
    },
  } ->
  package { $packages:
    ensure => present,
    notify => Archive['hedgedoc'],
  }

  file { $install_path:
    ensure  => 'directory',
    owner   => $user,
    group   => $group,
    mode    => '0644',
    require => [User[$user], Group[$group]],
  }

  archive { 'hedgedoc':
    path          => $archive_path,
    extract       => true,
    source        => $archive_url,
    extract_path  => $root_install_path,
    creates       => $install_path,
    checksum      => $archive_digest,
    checksum_type => $archive_digest_type,
    cleanup       => true,
    user          => 'root',
    group         => 'root',
    notify        => File[$install_path],
  } ~>
  exec {'active-initialize':
    command      => "touch ${upgrade_flag_path}",
    path         => '/usr/bin',
    refreshonly  => true,
  } ~>
  exec {'hedgedoc-flag-upgrade':
    command     => "$install_path/bin/setup",
    cwd         => $install_path,
    require     => Postgresql::Server::Db[$db_name],
    refreshonly => true,
  } ~>
  file {$sequelizerc_config_json_path:
    ensure  => present,
    owner   => $user,
    group   => $group,
    # Contains credentials
    mode    => '0600',
    content => template("profile/hedgedoc/config.json.erb"),
  } ~>
  file {$sequelizerc_config_sequelizerc_path:
    ensure  => present,
    owner   => $user,
    group   => $group,
    mode    => '0644',
    content => template("profile/hedgedoc/sequelizerc.erb"),
  } ~>
  exec {'yarn-build':
    command     => "yarn run build",
    cwd         => $install_path,
    path        => '/usr/bin',
    onlyif      => "test -f ${upgrade_flag_path}",
    refreshonly => true,
  } ~>
  exec {'hegdedoc-flag-upgrade-done':
    command     => "rm ${upgrade_flag_path}",
    cwd         => $install_path,
    path        => '/usr/bin',
    onlyif      => "test -f ${upgrade_flag_path}",
    refreshonly => true,
    notify      => Service[$service_name],
  }

  systemd::unit_file {$unit_name:
    ensure  => present,
    content => template('profile/hedgedoc/hedgedoc.service.erb'),
  }

  service {$service_name:
    ensure  => 'running',
    enable  => true,
    require => [
      Systemd::Unit_file[$unit_name],
      Package[$packages],
      Archive['hedgedoc'],
    ],
  }

}
