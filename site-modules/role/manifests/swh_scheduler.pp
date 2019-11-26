class role::swh_scheduler inherits role::swh_server {
  include profile::puppet::agent

  # Scheduler
  include profile::rabbitmq
  include profile::swh::deploy::scheduler
}
