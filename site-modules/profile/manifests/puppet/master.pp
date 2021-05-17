# Puppet master profile
class profile::puppet::master {
  $puppetdb = lookup('puppet::master::puppetdb')
  $codedir = lookup('puppet::master::codedir')

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
