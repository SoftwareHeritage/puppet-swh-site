class role::swh_logstash_instance inherits role::swh_base {
  include profile::logstash
  # Logstash node elected to close indices to avoid unbalance the cluster
  include profile::elasticsearch::index_janitor
  # manage the filebeat index templates
  include profile::filebeat::index_template_manager
}
