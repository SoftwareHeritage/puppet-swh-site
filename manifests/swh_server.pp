class role::swh_server inherits role::swh_base {
  include profile::dar::client
  include profile::rsyslog
}
