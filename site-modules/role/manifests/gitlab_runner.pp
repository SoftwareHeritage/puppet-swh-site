# Deployment of a gitlab runner node
class role::gitlab_runner inherits role::swh_base {
  include profile::zfs
  include profile::docker
}
