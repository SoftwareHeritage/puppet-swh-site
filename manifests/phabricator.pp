# Setup an instance of phabricator
class profile::phabricator {
  $phabricator_db_name = hiera('phabricator::mysql::database')
  $phabricator_db_user = hiera('phabricator::mysql::username')
  $phabricator_db_password = hiera('phabricator::mysql::password')
  $phabricator_db_max_allowed_packet = hiera('phabricator::mysql::conf::max_allowed_packet')
  $phabricator_db_sql_mode = hiera('phabricator::mysql::conf::sql_mode')
  $phabricator_db_ft_stopword_file = hiera('phabricator::mysql::conf::ft_stopword_file')
  $phabricator_fpm_listen = hiera('phabricator::php::fpm_listen')
  $phabricator_max_size = hiera('phabricator::php::max_file_size')
  $phabricator_vhost_name = hiera('phabricator::vhost::name')
  $phabricator_vhost_docroot = hiera('phabricator::vhost::docroot')

  include ::mysql::client

  class {'::mysql::server':
    override_options = {
      mysqld => {
        max_allowed_packet => $phabricator_db_max_allowed_packet,
        sql_mode           => $phabricator_db_sql_mode,
        ft_stopword_file   => $phabricator_db_ft_stopword_file,
      }
    }
  }

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
    listen          => $phabricator_fpm_listen,
    user            => 'www-data',
    php_admin_value => {
      post_max_size       => $phabricator_max_size,
      upload_max_filesize => $phabricator_max_size,
    },
  }

  ::php::module {[
    'mysql',
    'curl',
    'gd',
    'apcu',
  ]:
  }

  include ::apache
  include ::apache::mod::proxy

  ::apache::mod {'proxy_fcgi':}

  ::apache::vhost {"${phabricator_vhost_name} non-ssl":
    servername      => $phabricator_vhost_name,
    port            => '80',
    docroot         => $phabricator_vhost_docroot,
    redirect_status => 'permanent',
    redirect_dest   => "https://${phabricator_vhost_name}/",
  }

  ::apache::vhost {"${phabricator_vhost_name} ssl":
    servername => $phabricator_vhost_name,
    port       => '443',
    ssl        => true,
    docroot    => $phabricator_vhost_docroot,
    rewrites   => [
      { rewrite_rule => '^/rsrc/(.*) - [L,QSA]' },
      { rewrite_rule => '^/favicon.ico - [L,QSA]' },
      { rewrite_rule => "^(.*)$ fcgi://${phabricator_fpm_listen}${phabricator_vhost_docroot}/index.php?__path__=\$1 [B,L,P,QSA]" },
    ],
  }
}
