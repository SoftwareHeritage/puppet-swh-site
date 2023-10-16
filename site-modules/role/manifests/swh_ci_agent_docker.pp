class role::swh_ci_agent_docker inherits role::swh_ci_agent {
  include profile::jenkins::agent::docker
  include profile::zfs::docker
}
