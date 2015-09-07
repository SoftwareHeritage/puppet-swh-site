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
  include ::php::fpm::daemon

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
