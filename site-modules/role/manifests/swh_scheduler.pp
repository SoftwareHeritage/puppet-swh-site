class role::swh_scheduler inherits role::swh_server {
  # Scheduler
  include profile::rabbitmq
  include profile::swh::deploy::scheduler
}
