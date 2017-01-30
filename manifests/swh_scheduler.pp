class role::swh_scheduler inherits role::swh_server {
  include profile::network
  include profile::puppet::agent

  # Scheduler
  #include profile::munin::plugins::rabbitmq
  #include profile::swh::deploy::scheduler
}
