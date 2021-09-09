# deploy a netbox instance
class profile::netbox {

  $version = lookup('netbox::version')
  $netbox_user = lookup('netbox::user')
  $db_host = lookup('netbox::db::host')
  $db_port = lookup('netbox::db::port')
  $db_database = lookup('netbox::db::database')
  $db_username = lookup('netbox::db::username')
  $db_password = lookup('netbox::db::password')
  $secret_key = lookup('netbox::secret_key')
  $allowed_hosts = lookup('netbox::allowed_hosts')
  $redis_host = lookup('netbox::redis::host')
  $redis_port = lookup('netbox::redis::port')
  $redis_password = lookup('netbox::redis::password')
  $smtp_host = lookup('netbox::mail::host')
  $email_from = lookup('netbox::mail::from')
  $gunicorn_binding = lookup('netbox::gunicorn::binding')
  $gunicorn_port = lookup('netbox::gunicorn::port')
  $data_directory = lookup('netbox::data_directory')
  $media_directory = "${data_directory}/media"
  $reports_directory = "${data_directory}/reports"
  $scripts_directory = "${data_directory}/scripts"

  $archive_url = "https://github.com/netbox-community/netbox/archive/v${version}.tar.gz"
  $archive_path = "/opt/netbox-v${version}.tar.gz"
  $install_path = "/opt/netbox-${version}"
  $upgrade_flag_path = "${install_path}/.upgrade_done"

  ensure_packages ('python3-venv')

  include ::postgresql::server

  ::postgresql::server::db {$db_database:
    user     => $db_username,
    password => postgresql_password($db_username, $db_password),
    require  => [Class['Postgresql::Server']],
  }

  class { '::redis' :
    requirepass => $redis_password,
    bind        => '127.0.0.1',
    port        => $redis_port,
  }

  user {$netbox_user:
    ensure => present,
    system => true,
    shell  => '/bin/bash',
    home   => $data_directory,
  }

  archive { 'netbox':
    path         => $archive_path,
    source       => $archive_url,
    extract      => true,
    extract_path => '/opt',
    creates      => $install_path,
    cleanup      => true,
    user         => 'root',
    group        => 'root',
  }
  file { '/opt/netbox' :
    ensure  => link,
    target  => $install_path,
    owner   => 'root',
    group   => 'root',
    require => Archive['netbox'],
  }

  file { 'netbox-configuration':
    ensure  => present,
    path    => "${install_path}/netbox/netbox/configuration.py",
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('profile/netbox/configuration.py.erb'),
    require => Archive['netbox'],
    notify  => Service['netbox'],
  }

  file { 'netbox-gunicorn-config':
    ensure  => present,
    path    => "${install_path}/gunicorn.py",
    owner   => 'root',
    group   => 'root',
    content => template('profile/netbox/gunicorn.py.erb'),
    require => Archive['netbox'],
    notify  => Service['netbox'],
  }

  file { $data_directory :
    ensure  => directory,
    owner   => $netbox_user,
    group   => $netbox_user,
    mode    => '0750',
    require => User[$netbox_user]
  }
  file { $media_directory:
    ensure  => directory,
    owner   => $netbox_user,
    group   => $netbox_user,
    mode    => '0750',
    require => File[$data_directory],
  }
  file { $scripts_directory:
    ensure  => directory,
    owner   => $netbox_user,
    group   => $netbox_user,
    mode    => '0750',
    require => File[$data_directory],
  }
  file { $reports_directory:
    ensure  => directory,
    owner   => $netbox_user,
    group   => $netbox_user,
    mode    => '0750',
    require => File[$data_directory],
  }

  exec { 'netbox-upgrade':
    command => "${install_path}/upgrade.sh",
    cwd     => $install_path,
    creates => $upgrade_flag_path,
    require => [File['netbox-configuration'],
      File[$media_directory],
      Package['python3-venv'],
      Postgresql::Server::Db[$db_database],
    ],
    notify  => Exec['netbox-flag-upgrade-done'],
  }

  exec {'netbox-flag-upgrade-done':
    command     => "touch ${upgrade_flag_path}",
    path        => '/usr/bin',
    refreshonly => true,
  }

  ['netbox', 'netbox-rq'].each |$service| {

    Exec['netbox-flag-upgrade-done']
    ~> ::systemd::unit_file {"${service}.service":
      ensure  => present,
      content => template("profile/netbox/${service}.service.erb"),
    } ~> service {$service:
      ensure  => 'running',
      enable  => true,
      require => [File['netbox-gunicorn-config'],
                  File['netbox-configuration']],
    }
  }

  ::profile::cron::d {'netbox-housekeeping':
    target  => 'netbox',
    minute  => 'fqdn_rand',
    hour    => 'fqdn_rand',
    user    => $netbox_user,
    command => "chronic ${install_path}/venv/bin/python ${install_path}/netbox/manage.py housekeeping",
  }

}
