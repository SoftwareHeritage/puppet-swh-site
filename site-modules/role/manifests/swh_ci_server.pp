class role::swh_ci_server inherits role::swh_ci {
  include profile::jenkins::server
  include profile::jenkins::agent::docker
}
