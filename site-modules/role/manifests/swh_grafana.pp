class role::swh_grafana inherits role::swh_base {
  include profile::grafana::backend
}
