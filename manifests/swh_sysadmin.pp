class role::swh_sysadmin inherits role::swh_server {
  include profile::network

  include profile::munin::master
  include profile::munin::stats_export

  include profile::prometheus::server
  include profile::grafana

  include profile::prometheus::node
  include profile::prometheus::sql

  include profile::puppet::master

  include profile::icinga2::icingaweb2

  include profile::apache::simple_server
  include profile::bind_server
  include profile::munin::plugins::postgresql

  include profile::annex_web
  include profile::docs_web
  include profile::debian_repository
}
