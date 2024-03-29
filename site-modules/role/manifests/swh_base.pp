class role::swh_base {
  include profile::static_hostnames

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

  if $::virtual == 'physical' {
    include profile::megacli
  }

  include profile::cloudinit
  include profile::smartmontools
  include profile::network
  include profile::swh

  include profile::sanoid::sync_source
  include profile::sanoid::sync_destination
}
