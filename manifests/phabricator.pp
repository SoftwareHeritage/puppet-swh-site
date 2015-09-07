# Setup an instance of phabricator
class profile::phabricator {
  include ::apache

  include ::mysql::server
  include ::mysql::client

  $phabricator_db_name = hiera('phabricator::mysql::database')
  $phabricator_db_user = hiera('phabricator::mysql::username')
  $phabricator_db_password = hiera('phabricator::mysql::password')
  $phabricator_fpm_listen = hiera('phabricator::php::fpm_listen')

  ::mysql::db {$phabricator_db_name:
    user     => $phabricator_db_user,
    password => $phabricator_db_password,
    host     => 'localhost',
    grant    => ['ALL'],
  }

  include ::php::cli

  ::php::fpm::daemon {
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
}
