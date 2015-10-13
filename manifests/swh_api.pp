class role::swh_api inherits role::swh_server {
  include profile::network

  include profile::munin::plugins::rabbitmq
  include profile::swh::deploy::webapp
}
