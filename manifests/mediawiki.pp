# Deployment of mediawiki for the Software Heritage intranet
class profile::mediawiki {
  $mediawiki_fpm_root = hiera('mediawiki::php::fpm_listen')

  $mediawiki_db_user = hiera('mediawiki::mysql::username')
  $mediawiki_db_basename = hiera('mediawiki::mysql::dbname')
  $mediawiki_db_password = hiera('mediawiki::mysql::password')

  $mediawiki_vhost_name = hiera('mediawiki::vhost::name')
  $mediawiki_vhost_docroot = hiera('mediawiki::vhost::docroot')
  $mediawiki_vhost_basic_auth_content = hiera('mediawiki::vhost::basic_auth_content')
  $mediawiki_vhost_ssl_protocol = hiera('mediawiki::vhost::ssl_protocol')
  $mediawiki_vhost_ssl_honorcipherorder = hiera('mediawiki::vhost::ssl_honorcipherorder')
  $mediawiki_vhost_ssl_cipher = hiera('mediawiki::vhost::ssl_cipher')
  $mediawiki_vhost_hsts_header = hiera('mediawiki::vhost::hsts_header')

  $mediawiki_config_secret_key = hiera('mediawiki::conf::secret_key')
  $mediawiki_config_upgrade_key = hiera('mediawiki::conf::upgrade_key')

  include ::php::fpm::daemon

  ::php::fpm::conf {'mediawiki':
    listen => $mediawiki_fpm_root,
    user   => 'www-data',
  }

  include ::profile::ssl

  $ssl_cert_name = 'star_softwareheritage_org'
  $ssl_cert = $::profile::ssl::certificate_paths[$ssl_cert_name]
  $ssl_ca   = $::profile::ssl::ca_paths[$ssl_cert_name]
  $ssl_key  = $::profile::ssl::private_key_paths[$ssl_cert_name]

  include ::mediawiki

  ::mediawiki::instance { $mediawiki_vhost_name:
    vhost_docroot              => $mediawiki_vhost_docroot,
    vhost_fpm_root             => $mediawiki_fpm_root,
    vhost_basic_auth           => $mediawiki_vhost_basic_auth_content,
    vhost_ssl_protocol         => $mediawiki_vhost_ssl_protocol,
    vhost_ssl_honorcipherorder => $mediawiki_vhost_ssl_honorcipherorder,
    vhost_ssl_cipher           => $mediawiki_vhost_ssl_cipher,
    vhost_ssl_cert             => $ssl_cert,
    vhost_ssl_ca               => $ssl_ca,
    vhost_ssl_key              => $ssl_key,
    vhost_ssl_hsts_header      => $mediawiki_vhost_hsts_header,
    db_user                    => $mediawiki_db_user,
    db_basename                => $mediawiki_db_basename,
    db_host                    => 'localhost',
    db_password                => $mediawiki_db_password,
    secret_key                 => $mediawiki_config_secret_key,
    upgrade_key                => $mediawiki_config_upgrade_key,
  }
}
