# Deploy a Sentry instance
class profile::sentry {
  include profile::docker
  include profile::docker_compose

  $onpremise_dir = '/var/lib/sentry-onpremise'
  $onpremise_repo = 'https://forge.softwareheritage.org/source/getsentry-onpremise.git'
  $onpremise_repo_branch = 'softwareheritage'

  vcsrepo {$onpremise_dir:
    ensure   => latest,
    provider => 'git',
    source   => $onpremise_repo,
    revision => $onpremise_repo_branch,
    notify   => [
      File_Line['sentry_environment_kafka'],
      Exec['run sentry-onpremise install.sh'],
    ],
  } ->
  file {$onpremise_dir:
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0700',
  }

  $requirements_file = "${onpremise_dir}/sentry/requirements.txt"
  $config_yml = "${onpremise_dir}/sentry/config.yml"
  $config_py = "${onpremise_dir}/sentry/sentry.conf.py"
  $relay_credentials_json = "${onpremise_dir}/relay/credentials.json"
  $relay_config_yml = "${onpremise_dir}/relay/config.yml"
  $symbolicator_config_yml = "${onpremise_dir}/symbolicator/config.yml"
  $clickhouse_config_xml = "${onpremise_dir}/clickhouse/config.xml"
  $geoip_conf = "${onpremise_dir}/geoip/GeoIP.conf"

  file {$requirements_file:
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('profile/sentry/requirements.txt.erb'),
    require => Vcsrepo[$onpremise_dir],
    notify  => Exec['run sentry-onpremise install.sh'],
  }

  # variables for config.yml
  $admin_email = lookup('sentry::admin_email')
  $secret_key  = lookup('sentry::secret_key')
  $vhost_name  = lookup('sentry::vhost::name')
  $mail_host   = lookup('sentry::mail::host')
  $mail_from   = lookup('sentry::mail::from')
  $mail_list_namespace   = lookup('sentry::mail::list_namespace')

  file {$config_yml:
    ensure => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('profile/sentry/config.yml.erb'),
    require => Vcsrepo[$onpremise_dir],
    notify  => Exec['run sentry-onpremise install.sh'],
  }

  file {$relay_config_yml:
    ensure => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('profile/sentry/relay.yml.erb'),
    require => Vcsrepo[$onpremise_dir],
    notify  => Exec['run sentry-onpremise install.sh'],
  }

  file {$symbolicator_config_yml:
    ensure => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('profile/sentry/symbolicator.yml.erb'),
    require => Vcsrepo[$onpremise_dir],
    notify  => Exec['run sentry-onpremise install.sh'],
  }

  file {$clickhouse_config_xml:
    ensure => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('profile/sentry/clickhouse.xml.erb'),
    require => Vcsrepo[$onpremise_dir],
    notify  => Exec['run sentry-onpremise install.sh'],
  }

  #####
  # variables for sentry.conf.py
  # postgresql
  $postgres_host = lookup('sentry::postgres::host')
  $postgres_port = lookup('sentry::postgres::port')
  $postgres_dbname = lookup('sentry::postgres::dbname')
  $postgres_user = lookup('sentry::postgres::user')
  $postgres_password = lookup('sentry::postgres::password')


  # relay
  $relay_public_key = lookup('sentry::relay::public_key')

  #####
  file {$config_py:
    ensure => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('profile/sentry/sentry.conf.py.erb'),
    require => Vcsrepo[$onpremise_dir],
    notify  => Exec['run sentry-onpremise install.sh'],
  }

  $relay_secret_key = lookup('sentry::relay::secret_key')
  $relay_id = lookup('sentry::relay::id')

  file {$relay_credentials_json:
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('profile/sentry/relay_credentials.json.erb'),
    require => Vcsrepo[$onpremise_dir],
    notify  => Exec['run sentry-onpremise install.sh'],
  }

  $geoip_account_id = lookup('sentry::geoip::account_id')
  $geoip_license_key = lookup('sentry::geoip::license_key')

  file {$geoip_conf:
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('profile/sentry/geoip.conf.erb'),
    require => Vcsrepo[$onpremise_dir],
    notify  => Exec['run sentry-onpremise install.sh'],
  }

  file_line {'sentry_environment_kafka':
    ensure            => absent,
    path              => "${onpremise_dir}/.env",
    match             => '^DEFAULT_BROKERS=',
    match_for_absence => true,
    multiple          => true,
    require           => Vcsrepo[$onpremise_dir],
    notify            => Exec['run sentry-onpremise install.sh'],
  }

  file_line {'sentry_environment_mail_host':
    ensure            => present,
    path              => "${onpremise_dir}/.env",
    match             => '^(# )?SENTRY_MAIL_HOST=',
    line              => "SENTRY_MAIL_HOST=${mail_list_namespace}",
    multiple          => true,
    require           => Vcsrepo[$onpremise_dir],
    notify            => Exec['run sentry-onpremise install.sh'],
  }

  $onpremise_flag = "${onpremise_dir}-installed"
  $onpremise_log = "/var/log/sentry-onpremise-install.log"

  exec {'check sentry-onpremise install flag':
    command  => 'true',
    unless   => "bash -c '[[ \"$(cat ${onpremise_flag})\" = \"$(git rev-parse HEAD)\" ]]'",
    cwd      => $onpremise_dir,
    path     => ['/usr/local/sbin', '/usr/local/bin', '/usr/sbin', '/usr/bin', '/sbin:/bin'],
    notify   => Exec['run sentry-onpremise install.sh'],
  }

  exec {'run sentry-onpremise install.sh':
    command     => "rm -f ${onpremise_flag}; (./install.sh --minimize-downtime && git rev-parse HEAD > ${onpremise_flag}) | tee -a ${onpremise_log}",
    timeout     => 0,
    provider    => shell,
    cwd         => $onpremise_dir,
    path        => ['/usr/local/sbin', '/usr/local/bin', '/usr/sbin', '/usr/bin', '/sbin:/bin'],
    environment => ["CI=yes"],
    refreshonly => true,
    require     => [
      Class['profile::docker'],
      Package['docker-compose'],
      File[$requirements_file, $config_yml, $config_py],
    ],
    notify      => Exec['start sentry-onpremise docker compose'],
  }

  exec {'start sentry-onpremise docker compose':
    command     => 'docker-compose up -d',
    timeout     => 0,
    cwd         => $onpremise_dir,
    path        => ['/usr/local/sbin', '/usr/local/bin', '/usr/sbin', '/usr/bin', '/sbin:/bin'],
    refreshonly => true,
    require     => [
      Class['profile::docker'],
      Package['docker-compose'],
      File[$requirements_file, $config_yml, $config_py],
    ],
  }
}
