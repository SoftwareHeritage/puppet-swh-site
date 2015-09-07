# Setup an instance of phabricator
class profile::phabricator {
  include ::apache

  include ::mysql::server
  include ::mysql::client

  $phabricator_db_name = hiera('phabricator::mysql::database')
  $phabricator_db_user = hiera('phabricator::mysql::username')
  $phabricator_db_password = hiera('phabricator::mysql::password')
  $phabricator_fpm_listen = hiera('phabricator::php::fpm_listen')
  $phabricator_vhost_name = hiera('phabricator::vhost::name')
  $phabricator_vhost_docroot = hiera('phabricator::vhost::docroot')

  ::mysql::db {$phabricator_db_name:
    user     => $phabricator_db_user,
    password => $phabricator_db_password,
    host     => 'localhost',
    grant    => ['ALL'],
  }

  include ::php::cli

  class {'::php::fpm::daemon':
    log_owner    => 'www-data',
    log_group    => 'adm',
    log_dir_mode => '0750',
  }

  ::php::ini {'/etc/php5/cli/php.ini':}

  ::php::fpm::conf {'phabricator':
    listen => $phabricator_fpm_listen,
    user   => 'www-data',
  }

  ::php::module {[
    'mysql',
    'curl',
    'gd',
    'apcu',
  ]:
  }

  ::apache::mod {[
    'proxy_fcgi',
    'rewrite',
  ]: }

  ::apache::vhost {"${phabricator_vhost_name} non-ssl":
    servername      => $phabricator_vhost_name,
    port            => '80',
    docroot         => $phabricator_vhost_docroot,
    redirect_status => 'permanent',
    redirect_dest   => "https://${phabricator_vhost_name}/",
  }

  ::apache::vhost {"${phabricator_vhost_name} ssl":
    servername       => $phabricator_vhost_name,
    port             => '443',
    ssl              => true,
    docroot          => $phabricator_vhost_docroot,
    proxy_pass_match => {
      path => '/(.*\.php(/.*)?)$',
      url  => "fcgi://${phabricator_fpm_listen}/${phabricator_vhost_docroot}/\$1",
    },
    rewrites         => [
      { rewrite_rule => '^/rsrc/(.*)   -                      [L,QSA]' },
      { rewrite_rule => '^/favicon.ico -                      [L,QSA]' },
      { rewrite_rule => '^(.*)$        /index.php?__path__=$1 [B,L,QSA]' },
    ],
  }
}
