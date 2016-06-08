# Deployment of mediawiki for the Software Heritage intranet
class profile::mediawiki {
  $mediawiki_fpm_root = hiera('mediawiki::php::fpm_listen')

  $mediawiki_vhosts = hiera_hash('mediawiki::vhosts')

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

  $mediawiki_vhost_docroot = hiera('mediawiki::vhost::docroot')
  $mediawiki_vhost_ssl_protocol = hiera('mediawiki::vhost::ssl_protocol')
  $mediawiki_vhost_ssl_honorcipherorder = hiera('mediawiki::vhost::ssl_honorcipherorder')
  $mediawiki_vhost_ssl_cipher = hiera('mediawiki::vhost::ssl_cipher')
  $mediawiki_vhost_hsts_header = hiera('mediawiki::vhost::hsts_header')

  each ($mediawiki_vhosts) |$name, $data| {
    $secret_key = $data['secret_key']
    $upgrade_key = $data['upgrade_key']
    $basic_auth_content = $data['basic_auth']

    ::mediawiki::instance { $mediawiki_vhost_name:
      vhost_docroot              => $mediawiki_vhost_docroot,
      vhost_aliases              => $data['aliases'],
      vhost_fpm_root             => $mediawiki_fpm_root,
      vhost_basic_auth           => $basic_auth_content,
      vhost_ssl_protocol         => $mediawiki_vhost_ssl_protocol,
      vhost_ssl_honorcipherorder => $mediawiki_vhost_ssl_honorcipherorder,
      vhost_ssl_cipher           => $mediawiki_vhost_ssl_cipher,
      vhost_ssl_cert             => $ssl_cert,
      vhost_ssl_ca               => $ssl_ca,
      vhost_ssl_key              => $ssl_key,
      vhost_ssl_hsts_header      => $mediawiki_vhost_hsts_header,
      db_host                    => 'localhost',
      db_basename                => $data['mysql']['dbname'],
      db_user                    => $data['mysql']['user'],
      db_password                => $data['mysql']['password'],
      secret_key                 => $secret_key,
      upgrade_key                => $upgrade_key,
    }
  }
}
