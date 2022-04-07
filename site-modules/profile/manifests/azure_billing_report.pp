# Install and configure the azure
class profile::azure_billing_report {
  $billing_user = 'azbilling'
  $install_path = '/opt/azure_billing'
  $data_path = '/var/lib/azure_billing'
  $installed_flag = "${data_path}/.pip_updated"

  $azure_user = lookup('azure_billing::user')
  $azure_password = lookup('azure_billing::password')

  $packages = ['python3-venv', 'python3-pip', 'chromium-driver']

  ensure_packages($packages)

  user {$billing_user:
    ensure => present,
    system => true,
    shell  => '/bin/bash',
    home   => $data_path,
  }

  file { '/var/lib/azure_billing':
    ensure => directory,
    owner  => $billing_user,
    group  => 'root',
    mode   => '0744',
  }

  # Install the scripts
  file { $install_path:
    ensure  => directory,
    recurse => true,
    purge   => true,
    owner   => $billing_user,
    group   => 'root',
    source  => 'puppet:///modules/profile/azure_billing_report',
    notify  => Exec['azure_billing_prepare_pip'],
  }

  file { "${install_path}/refresh_azure_report.sh":
    ensure => present,
    source => 'puppet:///modules/profile/azure_billing_report/refresh_azure_report.sh',
    owner  => $billing_user,
    group  => 'root',
    mode   => '0744'
  }

  # create the venv if it doesn't exist already
  exec { 'azure_billing_venv':
    command => "sudo -u ${billing_user} python3 -m venv ${data_path}/.venv",
    path    => '/usr/bin',
    creates => "${data_path}/.venv",
    notify  => Exec['azure_billing_prepare_pip'],
    require => [User[$billing_user], File[$data_path], Package['python3-venv']],
  }

  # run pip install if there is any changes in the scripts
  exec { 'azure_billing_prepare_pip':
    command     => 'rm -f /var/lib/azure_billing/.installed',
    path        => '/usr/bin',
    refreshonly => true,
    notify      => Exec['azure_billing_pip_install'],
    require     => Exec['azure_billing_venv'],
  }

  exec { 'azure_billing_pip_install':
    command     => "sudo -u ${billing_user} ${data_path}/.venv/bin/pip install -r ${install_path}/requirements.txt && touch ${installed_flag}",
    path        => '/usr/bin',
    refreshonly => true,
    creates     => $installed_flag,
    require     => User[$billing_user],
  }

  # Create the service and configuration
  file {'/etc/default/azure-billing-report':
    ensure  => present,
    content => template('profile/azure_billing_report/azure-billing-report.default.erb'),
    owner   => $billing_user,
    group   => 'root',
    mode    => '0660',
  }

  $service_basename = 'azure-billing-report'

  ::systemd::timer { "${service_basename}.timer":
    timer_content   => template('profile/azure_billing_report/azure-billing-report.timer.erb'),
    service_content => template('profile/azure_billing_report/azure-billing-report.service.erb'),
    service_unit    => "${service_basename}.service",
    active          => true,
    enable          => true,
  }

  # site configuration
  $vhost_name = lookup('azure_billing::vhost::name')
  $vhost_ssl_protocol = lookup('azure_billing::vhost::ssl_protocol')
  $vhost_ssl_honorcipherorder = lookup('azure_billing::vhost::ssl_honorcipherorder')
  $vhost_ssl_cipher = lookup('azure_billing::vhost::ssl_cipher')
  $vhost_hsts_header = lookup('azure_billing::vhost::hsts_header')

  ::apache::vhost {"${vhost_name}_non-ssl":
    servername      => $vhost_name,
    port            => '80',
    docroot         => $data_path,
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
    docroot              => $data_path,
    manage_docroot       => false,
    require              => [
      File[$cert_paths['cert']],
      File[$cert_paths['chain']],
      File[$cert_paths['privkey']],
    ],
  }

  File[$cert_paths['cert'], $cert_paths['chain'], $cert_paths['privkey']] ~> Class['Apache::Service']

  $icinga_checks_file = lookup('icinga2::exported_checks::filename')

  @@::icinga2::object::service {"Azure billing report http redirect on ${::fqdn}":
    service_name  => 'azure billing report http redirect',
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

  @@::icinga2::object::service {"Azure billing report https on ${::fqdn}":
    service_name  => 'azure billing report https',
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

  @@::icinga2::object::service {"azure billing report https certificate ${::fqdn}":
    service_name  => 'azure billing report https certificate',
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
