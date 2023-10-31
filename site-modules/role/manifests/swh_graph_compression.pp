# SWH graph compression server
class role::swh_graph_compression inherits role::swh_base {
  include profile::zfs
  include profile::swh::deploy::graph::shm_mount
}
