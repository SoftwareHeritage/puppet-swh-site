class role::swh_logstash_instance inherits role::swh_base {
  include profile::logstash
  # manage elasticsearch indices
  include profile::elasticsearch::indices_curator
  # manage the filebeat index templates
  include profile::filebeat::index_template_manager
}
