class role::swh_ci_agent inherits role::swh_ci {
  include profile::jenkins::agent
}
