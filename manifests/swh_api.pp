class role::swh_api {
  include profile::base
  include profile::ssh::server
  include profile::munin::node
  include profile::dar::client
  include profile::munin::plugins::rabbitmq
}
