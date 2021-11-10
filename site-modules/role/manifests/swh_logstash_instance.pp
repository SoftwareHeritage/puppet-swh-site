class role::swh_logstash_instance inherits role::swh_base {
  include profile::logstash
  # Logstash node elected to close indices to avoid unbalance the cluster
  include profile::elasticsearch::index_janitor
  # manage the journalbeat index templates
  include profile::journalbeat::index_template_manager
}
