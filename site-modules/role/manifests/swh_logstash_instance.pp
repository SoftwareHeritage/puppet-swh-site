class role::swh_logstash_instance inherits role::swh_base {
  include profile::puppet::agent
  include profile::logstash
}
