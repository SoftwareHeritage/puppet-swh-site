class role::swh_grafana inherits role::swh_server {
  include profile::grafana::backend
}
