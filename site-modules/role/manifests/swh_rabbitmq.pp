class role::swh_rabbitmq inherits role::swh_server {
  include profile::rabbitmq
}
