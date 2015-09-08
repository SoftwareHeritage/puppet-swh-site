class role::swh_api inherits role::swh_server {
  include profile::munin::plugins::rabbitmq
  include profile::worker::deploy_key
}
