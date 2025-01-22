# Puppet server profile
class profile::puppet::server {
  $puppetdb = lookup('puppet::server::puppetdb')
  $codedir = lookup('puppet::server::codedir')
  $reports_retention = lookup('puppet::server::reports_retention')

  $manage_puppetdb = lookup('puppet::server::manage_puppetdb')

  $jvm_heap_size = lookup('puppet::server::jvm::heap_size')
  $jvm_extra_args = lookup('puppet::server::jvm::extra_args')
  $max_active_instances = lookup('puppet::server::max_active_instances')

  # Pergamon installation was done manually, we ensure nothing
  # is touched in production
  if $manage_puppetdb {
    # $puppetdb_listen_address = lookup('puppetdb::listen_address')
    $puppetdb_etcdir = lookup('swh::puppetdb::etcdir')
    $puppetdb_ssl_cert_path = lookup('swh::puppetdb::ssl_cert_path')
    $puppetdb_ssl_key_path = lookup('swh::puppetdb::ssl_key_path')
    $puppetdb_ssl_ca_cert_path = lookup('swh::puppetdb::ssl_ca_cert_path')

    $puppetdb_ssl_cert = lookup('swh::puppetdb::ssl_cert')
    $puppetdb_ssl_key = lookup('swh::puppetdb::ssl_key')
    $puppetdb_ssl_ca_cert = lookup('swh::puppetdb::ssl_ca_cert')

    file { $puppetdb_etcdir:
      ensure => directory,
      owner  => 'root',
      group  => 'root',
      mode   => '0775'
    }

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
      require             => [Class['Profile::Swh::Apt_config'],
          File[$puppetdb_etcdir]],
    }
  }

  class { '::puppet':
    server                      => true,
    server_common_modules_path  => '',
    server_external_nodes       => '',
    server_foreman              => false,
    server_reports              => 'store,puppetdb',
    server_storeconfigs         => true,
    server_jvm_min_heap_size    => $jvm_heap_size,
    server_jvm_max_heap_size    => $jvm_heap_size,
    server_jvm_extra_args       => $jvm_extra_args,
    server_max_active_instances => $max_active_instances,
    codedir                     => $codedir,

    *                           => $::profile::puppet::agent_config,
  }

  class { '::puppet::server::puppetdb':
    server => $puppetdb,
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

  file { '/usr/local/sbin/swh-puppet-master-decommission':
    ensure  => 'file',
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    content => template('profile/puppet/swh-puppet-master-decommission.sh.erb'),
  }

  profile::cron::d {'gzip-puppet-reports':
    target  => 'puppet',
    command => 'find /var/lib/puppet/reports -type f -not -name \'*.gz\' -exec gzip {} \+',
    minute  => 'fqdn_rand',
    hour    => 'fqdn_rand/4',
  }

  profile::cron::d {'purge-puppet-reports':
    target  => 'puppet',
    command => "find /var/lib/puppet/reports -type f -mtime +${reports_retention} -delete",
    minute  => 'fqdn_rand',
    hour    => 'fqdn_rand',
  }

  profile::cron::d {'gzip-puppetserver-reports':
    target  => 'puppet',
    command => 'find /var/lib/puppetserver/reports -type f -not -name \'*.gz\' -exec gzip {} \+',
    minute  => 'fqdn_rand',
    hour    => 'fqdn_rand/4',
  }

  profile::cron::d {'purge-puppetserver-reports':
    target  => 'puppet',
    command => "find /var/lib/puppetserver/reports -type f -mtime +${reports_retention} -delete",
    minute  => 'fqdn_rand',
    hour    => 'fqdn_rand',
  }
}
