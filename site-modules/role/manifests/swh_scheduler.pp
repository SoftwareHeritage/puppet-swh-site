class role::swh_scheduler inherits role::swh_server {
  include profile::rabbitmq
}
