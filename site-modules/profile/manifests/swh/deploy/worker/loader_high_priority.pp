# Deployment for high priority loader
class profile::swh::deploy::worker::loader_high_priority {
  ::profile::swh::deploy::worker::instance {'loader_high_priority':
    ensure => absent,
  }
}
