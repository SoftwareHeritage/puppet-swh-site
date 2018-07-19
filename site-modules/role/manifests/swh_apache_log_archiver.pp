class role::swh_apache_log_archiver inherits role::swh_base {
  include profile::puppet::agent
  include profile::filebeat
}
