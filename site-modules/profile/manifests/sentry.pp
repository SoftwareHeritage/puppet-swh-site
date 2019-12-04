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
  }

  $requirements_file = "${onpremise_dir}/sentry/requirements.txt"
  $config_yml = "${onpremise_dir}/sentry/config.yml"
  $config_py = "${onpremise_dir}/sentry/sentry.conf.py"

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
  $secret_key = lookup('sentry::secret_key')

  file {$config_yml:
    ensure => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0600',
    content => template('profile/sentry/config.yml.erb'),
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

  # kafka
  $kafka_clusters = lookup('kafka::clusters', Hash)
  $kafka_cluster = lookup('sentry::kafka_cluster')
  $kafka_bootstrap_servers = $kafka_clusters[$kafka_cluster]['brokers'].keys.join(',')

  #####
  file {$config_py:
    ensure => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0600',
    content => template('profile/sentry/sentry.conf.py.erb'),
    require => Vcsrepo[$onpremise_dir],
    notify  => Exec['run sentry-onpremise install.sh'],
  }

  file_line {'sentry_environment_kafka':
    ensure  => present,
    path    => "${onpremise_dir}/.env",
    match   => '^DEFAULT_BROKERS=',
    line    => "DEFAULT_BROKERS=${kafka_bootstrap_servers}",
    require => Vcsrepo[$onpremise_dir],
    notify  => Exec['run sentry-onpremise install.sh'],
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
    command     => "rm -f ${onpremise_flag}; (./install.sh && git rev-parse HEAD > ${onpremise_flag}) | tee -a ${onpremise_log}",
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
