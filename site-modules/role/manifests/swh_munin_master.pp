class role::swh_munin_master inherits role::swh_server {
  include profile::network

  include profile::munin::master
  include profile::munin::stats_export
}
