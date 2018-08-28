class role::swh_sysadmin inherits role::swh_server {
  include profile::network

  include profile::munin::master
  include profile::munin::stats_export
}
