class role::swh_hedgedoc inherits role::swh_database {
  include profile::postgresql::server
  include profile::hedgedoc
}
