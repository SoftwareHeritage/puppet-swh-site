class role::swh_base {
  include profile::base
  include profile::ssh::server
  include profile::unbound
  include profile::systemd_journal
  include profile::resolv_conf
  include profile::puppet
  include profile::prometheus::node
  include profile::prometheus::statsd
  include profile::icinga2
  include profile::rsyslog


  include profile::swh
}
