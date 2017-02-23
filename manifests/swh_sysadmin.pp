class role::swh_sysadmin inherits role::swh_server {
  include profile::network

  include profile::munin::master
  include profile::munin::stats_export
  #include profile::puppet::agent
  #include profile::puppet::master
  include profile::apache::simple_server
  include profile::bind_server
  include profile::munin::plugins::postgresql

  include profile::annex_web

  Class['profile::bind_server'] -> Class['profile::resolv_conf']
}
