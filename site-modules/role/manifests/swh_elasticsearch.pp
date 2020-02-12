class role::swh_elasticsearch inherits role::swh_base {
  include profile::elasticsearch

  include profile::kafka::broker
}
