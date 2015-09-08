class role::swh_forge inherits role::swh_server {
  include profile::network

  include profile::phabricator
}
