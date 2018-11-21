class role::swh_ci_agent_debian inherits role::swh_ci_agent {
  include profile::jenkins::agent::sbuild
}
