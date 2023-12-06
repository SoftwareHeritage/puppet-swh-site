class role::swh_rancher_agent_with_journal inherits role::swh_server {
  include profile::postgresql::client

  # journal
  include profile::zookeeper
  include profile::kafka::broker

  # Make this node a rancher agent too
  include profile::zfs::kubelet
  include profile::zfs::rancher
  include profile::mountpoints
  include profile::kubernetes
}
