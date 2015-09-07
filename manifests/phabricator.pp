# Setup an instance of phabricator
class profile::phabricator {
  include ::apache

  include ::mysql::server
  include ::mysql::client

  $phabricator_db_name = hiera('phabricator::mysql::database')
  $phabricator_db_user = hiera('phabricator::mysql::username')
  $phabricator_db_password = hiera('phabricator::mysql::password')
  $phabricator_db_password_hashed = hiera('phabricator::mysql::password_hashed')

  ::mysql::db {$phabricator_db_name:
    user     => $phabricator_db_user,
    password => $phabricator_db_password_hashed,
    host     => 'localhost',
    grant    => ['ALL PRIVILEGES'],
  }
}
