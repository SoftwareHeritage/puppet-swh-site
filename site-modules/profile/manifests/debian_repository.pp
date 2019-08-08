# Debian repository configuration

class profile::debian_repository {
  $packages = ['reprepro']

  package {$packages:
    ensure => installed,
  }

  $basepath =  lookup('debian_repository::basepath')

  $owner = lookup('debian_repository::owner')
  $group = lookup('debian_repository::group')
  $mode = lookup('debian_repository::mode')

  $owner_homedir = lookup('debian_repository::owner::homedir')

  user {$owner:
    ensure => present,
    system => true,
    home   => $owner_homedir,
  }
  -> file {$owner_homedir:
    ensure => 'directory',
    owner  => $owner,
    group  => $owner,
    mode   => '0750',
  }
  -> file {"${owner_homedir}/.ssh":
    ensure => 'directory',
    owner  => $owner,
    group  => $owner,
    mode   => '0700',
  }

  $authorized_keys = lookup('debian_repository::ssh_authorized_keys', Hash)
  each($authorized_keys) |$name, $key| {
    ssh_authorized_key { "${owner} ${name}":
      ensure  => 'present',
      user    => $owner,
      key     => $key['key'],
      type    => $key['type'],
      require => File["${owner_homedir}/.ssh"],
    }
  }

  file {$basepath:
    ensure => 'directory',
    owner  => $owner,
    group  => $group,
    mode   => $mode,
  }

  $incoming = "${basepath}/incoming"

  file {$incoming:
    ensure => 'directory',
    owner  => $owner,
    group  => $group,
    mode   => $mode,
  }

  $gpg_keys = lookup('debian_repository::gpg_keys', Array)

  $gpg_raw_command = 'gpg --batch --pinentry-mode loopback'
  each($gpg_keys) |$keyid| {
    exec {"debian repository gpg key ${keyid}":
      path    => ['/usr/bin'],
      command => "${gpg_raw_command} --recv-keys ${keyid}",
      user    => $owner,
      unless  => "${gpg_raw_command} --list-keys ${keyid}",
    }

    profile::cron::d {"debrepo-keyring-refresh-${keyid}":
      target      => 'debrepo-keyring-refresh',
      user        => $owner,
      command     => "chronic ${gpg_raw_command} --recv-keys ${keyid}",
      random_seed => "debrepo-keyring-${keyid}",
      minute      => 'fqdn_rand',
      hour        => 'fqdn_rand',
    }
  }

  file {"$basepath/conf":
    ensure => 'directory',
    owner  => $owner,
    group  => $group,
    mode   => $mode,
  }

  file {"$basepath/conf/uploaders":
    ensure  => 'file',
    owner   => $owner,
    group   => $group,
    mode    => '0644',
    content => template('profile/debian_repository/uploaders.erb')
  }

  $vhost_name = lookup('debian_repository::vhost::name')
  $vhost_aliases = lookup('debian_repository::vhost::aliases')
  $vhost_docroot = lookup('debian_repository::vhost::docroot')
  $vhost_ssl_protocol = lookup('debian_repository::vhost::ssl_protocol')
  $vhost_ssl_honorcipherorder = lookup('debian_repository::vhost::ssl_honorcipherorder')
  $vhost_ssl_cipher = lookup('debian_repository::vhost::ssl_cipher')
  $vhost_hsts_header = lookup('debian_repository::vhost::hsts_header')

  include ::profile::ssl
  include ::profile::apache::common

  ::apache::vhost {"${vhost_name}_non-ssl":
    servername      => $vhost_name,
    serveraliases   => $vhost_aliases,
    port            => '80',
    docroot         => $vhost_docroot,
    manage_docroot  => false,
    redirect_status => 'permanent',
    redirect_dest   => "https://${vhost_name}/",
  }

  $ssl_cert_name = 'star_softwareheritage_org'
  $ssl_cert = $::profile::ssl::certificate_paths[$ssl_cert_name]
  $ssl_chain   = $::profile::ssl::chain_paths[$ssl_cert_name]
  $ssl_key  = $::profile::ssl::private_key_paths[$ssl_cert_name]

  ::apache::vhost {"${vhost_name}_ssl":
    servername           => $vhost_name,
    port                 => '443',
    ssl                  => true,
    ssl_protocol         => $vhost_ssl_protocol,
    ssl_honorcipherorder => $vhost_ssl_honorcipherorder,
    ssl_cipher           => $vhost_ssl_cipher,
    ssl_cert             => $ssl_cert,
    ssl_chain            => $ssl_chain,
    ssl_key              => $ssl_key,
    headers              => [$vhost_hsts_header],
    docroot              => $vhost_docroot,
    manage_docroot       => false,
    directories          => [
      {
        path    => $vhost_docroot,
        require => 'all granted',
        options => ['Indexes', 'FollowSymLinks', 'MultiViews'],
      },
    ],
    require              => [
        File[$ssl_cert],
        File[$ssl_chain],
        File[$ssl_key],
    ],
  }

  $icinga_checks_file = '/etc/icinga2/conf.d/exported-checks.conf'

  @@::icinga2::object::service {"debian repository http redirect on ${::fqdn}":
    service_name  => 'debian repository http redirect',
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

  @@::icinga2::object::service {"debian repository https on ${::fqdn}":
    service_name  => 'debian repository https',
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

  @@::icinga2::object::service {"debian repository https certificate ${::fqdn}":
    service_name  => 'debian repository https certificate',
    import        => ['generic-service'],
    host_name     => $::fqdn,
    check_command => 'http',
    vars          => {
      http_address     => $vhost_name,
      http_vhost       => $vhost_name,
      http_ssl         => true,
      http_sni         => true,
      http_certificate => 60,
    },
    target        => $icinga_checks_file,
    tag           => 'icinga2::exported',
  }
}
