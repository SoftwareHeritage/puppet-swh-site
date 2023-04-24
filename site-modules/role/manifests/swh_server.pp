class role::swh_server inherits role::swh_base {
  include profile::borg::client
}
