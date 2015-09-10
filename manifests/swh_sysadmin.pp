class role::swh_sysadmin inherits role::swh_server {
  include profile::network

  include profile::munin::master
  #include profile::puppet::master
  include profile::apache::simple_server
  include profile::bind_server
  include profile::munin::plugins::postgresql
}
