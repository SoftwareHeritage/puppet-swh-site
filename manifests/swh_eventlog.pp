class role::swh_eventlog inherits role::swh_server {
  include profile::puppet::agent

  include profile::icinga2::agent

  include profile::kafka::server
  include profile::swh::deploy::storage_listener
}
