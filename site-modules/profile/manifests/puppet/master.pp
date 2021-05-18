# Puppet master profile
class profile::puppet::master {
  $puppetdb = lookup('puppet::master::puppetdb')
  $codedir = lookup('puppet::master::codedir')

  $manage_puppetdb = lookup('puppet::master::manage_puppetdb')

  # Pergamon installation was done manually, we ensure nothing
  # is touched in production
  if $manage_puppetdb {
    # $puppetdb_listen_address = lookup('puppetdb::listen_address')
    $puppetdb_ssl_cert_path = lookup('swh::puppetdb::ssl_cert_path')
    $puppetdb_ssl_key_path = lookup('swh::puppetdb::ssl_key_path')
    $puppetdb_ssl_ca_cert_path = lookup('swh::puppetdb::ssl_ca_cert_path')

    $puppetdb_ssl_cert = lookup('swh::puppetdb::ssl_cert')
    $puppetdb_ssl_key = lookup('swh::puppetdb::ssl_key')
    $puppetdb_ssl_ca_cert = lookup('swh::puppetdb::ssl_ca_cert')

    class { '::puppetdb':
      # confdir             => '/etc/puppetdb/conf.d',
      vardir              => '/var/lib/puppetdb',
      manage_firewall     => false,
      ssl_set_cert_paths  => true,
      # ssl_dir             => '/etc/puppetdb/ssl',
      ssl_cert_path       => $puppetdb_ssl_cert_path,
      ssl_key_path        => $puppetdb_ssl_key_path,
      ssl_ca_cert_path    => $puppetdb_ssl_ca_cert_path,
      ssl_cert            => file($puppetdb_ssl_cert),
      ssl_key             => file($puppetdb_ssl_key),
      ssl_ca_cert         => file($puppetdb_ssl_ca_cert),
      manage_package_repo => false, # already manage by swh::apt_config
      postgres_version    => '11',
      ssl_deploy_certs    => true,
      require             => [Class['Profile::Swh::Apt_config']],
    }
  }

  class { '::puppet':
    server                      => true,
    server_common_modules_path  => '',
    server_environments         => [],
    server_external_nodes       => '',
    server_foreman              => false,
    server_passenger            => true,
    server_puppetdb_host        => $puppetdb,
    server_reports              => 'store,puppetdb',
    server_storeconfigs_backend => 'puppetdb',
    codedir                     => $codedir,

    *                           => $::profile::puppet::agent_config,
  }

  # Extra configuration for fileserver
  $letsencrypt_export_dir = lookup('letsencrypt::certificates::exported_directory')
  file { '/etc/puppet/fileserver.conf':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('profile/puppet/fileserver.conf.erb')
  }

  file { '/usr/local/sbin/swh-puppet-master-deploy':
    ensure  => 'file',
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    content => template('profile/puppet/swh-puppet-master-deploy.sh.erb'),
  }

  file {'/usr/local/sbin/swh-puppet-master-clean-certificate':
    ensure => absent,
  }

  file { '/usr/local/sbin/swh-puppet-master-decomission':
    ensure  => 'file',
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    content => template('profile/puppet/swh-puppet-master-decomission.sh.erb'),
  }

  profile::cron::d {'gzip-puppet-reports':
    target  => 'puppet',
    command => 'find /var/lib/puppet/reports -type f -not -name *.gz -exec gzip {} \+',
    minute  => 'fqdn_rand',
    hour    => 'fqdn_rand/4',
  }

  profile::cron::d {'purge-puppet-reports':
    target  => 'puppet',
    command => 'find /var/lib/puppet/reports -type f -mtime +30 -delete',
    minute  => 'fqdn_rand',
    hour    => 'fqdn_rand',
  }

}
