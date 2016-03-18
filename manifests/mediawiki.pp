# Deployment of mediawiki for the Software Heritage intranet
class profile::mediawiki {
  $mediawiki_db_user = hiera('mediawiki::mysql::username')
  $mediawiki_db_basename = hiera('mediawiki::mysql::dbname')
  $mediawiki_db_password = hiera('mediawiki::mysql::password')

  $mediawiki_fpm_listen = hiera('mediawiki::php::fpm_listen')

  $mediawiki_vhost_name = hiera('mediawiki::vhost::name')
  $mediawiki_vhost_docroot = hiera('mediawiki::vhost::docroot')
  $mediawiki_vhost_basic_auth_file = "/etc/apache2/mediawiki_http_auth"
  $mediawiki_vhost_basic_auth_content = hiera('mediawiki::vhost::basic_auth_content')
  $mediawiki_vhost_ssl_protocol = hiera('mediawiki::vhost::ssl_protocol')
  $mediawiki_vhost_ssl_honorcipherorder = hiera('mediawiki::vhost::ssl_honorcipherorder')
  $mediawiki_vhost_ssl_cipher = hiera('mediawiki::vhost::ssl_cipher')
  $mediawiki_vhost_hsts_header = hiera('mediawiki::vhost::hsts_header')

  $mediawiki_config = "/etc/mediawiki/LocalSettings_${mediawiki_vhost_name}.php"
  $mediawiki_config_meta = "/etc/mediawiki/LocalSettings.php"
  $mediawiki_config_secret_key = hiera('mediawiki::conf::secret_key')
  $mediawiki_config_upgrade_key = hiera('mediawiki::conf::upgrade_key')

  $packages = [
    'mediawiki',
    'mediawiki-extensions',
  ]

  package {$packages:
    ensure => latest,
  }

  include ::mysql::client

  ::mysql::db {$mediawiki_db_basename:
    user     => $mediawiki_db_username,
    password => $mediawiki_db_password,
    host     => 'localhost',
    grant    => ['ALL'],
  }

  include ::php::fpm::daemon

  ::php::fpm::conf {'mediawiki':
    listen => $mediawiki_fpm_listen,
    user   => 'www-data',
  }

  include ::profile::ssl
  include ::apache
  include ::apache::mod::proxy
  include ::profile::apache::mod_proxy_fcgi

  ::apache::vhost {"${mediawiki_vhost_name}_non-ssl":
    servername      => $mediawiki_vhost_name,
    port            => '80',
    docroot         => $mediawiki_vhost_docroot,
    redirect_status => 'permanent',
    redirect_dest   => "https://${mediawiki_vhost_name}/",
  }

  $ssl_cert_name = 'star_softwareheritage_org'
  $ssl_cert = $::profile::ssl::certificate_paths[$ssl_cert_name]
  $ssl_ca   = $::profile::ssl::ca_paths[$ssl_cert_name]
  $ssl_key  = $::profile::ssl::private_key_paths[$ssl_cert_name]

  ::apache::vhost {"${mediawiki_vhost_name}_ssl":
    servername           => $mediawiki_vhost_name,
    port                 => '443',
    ssl                  => true,
    ssl_protocol         => $mediawiki_vhost_ssl_protocol,
    ssl_honorcipherorder => $mediawiki_vhost_ssl_honorcipherorder,
    ssl_cipher           => $mediawiki_vhost_ssl_cipher,
    ssl_cert             => $ssl_cert,
    ssl_ca               => $ssl_ca,
    ssl_key              => $ssl_key,
    headers              => [$mediawiki_vhost_hsts_header],
    docroot              => $mediawiki_vhost_docroot,
    proxy_pass_match     => [
      { path => '^/(.*\.php(/.*)?)$',
        url  => "fcgi://${mediawiki_fpm_listen}${mediawiki_vhost_docroot}/\$1",
      },
    ],
    directories          => [
      { path           => '/',
        provider       => 'location',
        auth_type      => 'Basic',
        auth_name      => 'Software Heritage development',
        auth_user_file => $mediawiki_vhost_basic_auth_file,
        auth_require   => 'valid-user',
      },
      { path           => "${mediawiki_vhost_docroot}/config",
        provider       => 'directory',
        override       => ['None'],
      },
      { path           => "${mediawiki_vhost_docroot}/images",
        provider       => 'directory',
        override       => ['None'],
      },
      { path           => "${mediawiki_vhost_docroot}/upload",
        provider       => 'directory',
        override       => ['None'],
      },
    ],
    require              => [
      File[$mediawiki_vhost_basic_auth_file],
      File[$mediawiki_config],
      File[$mediawiki_config_meta],
      File[$ssl_cert],
      File[$ssl_ca],
      File[$ssl_key],
    ],
  }

  file {$mediawiki_vhost_basic_auth_file:
    ensure  => present,
    owner   => 'root',
    group   => 'www-data',
    mode    => '0640',
    content => $mediawiki_vhost_basic_auth_content,
  }

  file {$mediawiki_config_meta:
    ensure  => present,
    owner   => 'root',
    group   => 'www-data',
    mode    => '0640',
    # TODO actually use this to generate a proper vhost dispatcher config file
    # XXX currently LocalSettings.php should be hand maintained when modifying vhosts
    # content => template('profile/mediawiki/LocalSettings.php.erb'),
    require => Package['mediawiki'],
  }

  file {$mediawiki_config:
    ensure  => present,
    owner   => 'root',
    group   => 'www-data',
    mode    => '0640',
    content => template('profile/mediawiki/LocalSettings_vhost.php.erb'),
    require => Package['mediawiki'],
    notify  => Service['php5-fpm'],
  }
}
