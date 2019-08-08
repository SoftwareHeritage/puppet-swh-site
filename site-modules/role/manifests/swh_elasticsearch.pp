class role::swh_elasticsearch inherits role::swh_base {
  include profile::puppet::agent
  include profile::elasticsearch

  include profile::kafka::broker
}
