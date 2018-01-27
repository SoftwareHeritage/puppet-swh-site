class role::swh_base {
  include profile::base
  include profile::ssh::server
  include profile::unbound
  include profile::systemd_journal
  include profile::resolv_conf
  include profile::munin::node
  include profile::icinga2
  include profile::rsyslog


  include profile::swh
}
