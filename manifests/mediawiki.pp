# Deployment of mediawiki for the Software Heritage intranet
class profile::mediawiki {
  $mediawiki_db_user = hiera('mediawiki::mysql::username')
  $mediawiki_db_baename = hiera('mediawiki::mysql::dbname')
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

  $packages = [
    'mediawiki',
    'mediawiki-extensions',
  ]

  package {$packages:
    ensure => latest,
  }

  include ::mysql::client

  $mysql_username = "${mediawiki_db_user}@localhost"
  $mysql_tables = "${mediawiki_db_basename}.*"

  mysql_user {$mysql_username:
    ensure        => present,
    password_hash => mysql_password($mediawiki_db_password),
  }

  mysql_grant {"${mysql_username}/${mysql_tables}":
    user       => $mysql_username,
    table      => $mysql_tables,
    privileges => ['ALL'],
    require    => Mysql_user[$mysql_username],
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
}
