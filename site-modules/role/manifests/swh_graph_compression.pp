# SWH graph compression server
class role::swh_graph_compression inherits role::swh_base {
  include profile::zfs

  # For manually run experiments on maxxi
  # NOTE: ZFS dataset was created by hand (the pool on maxxi is named `ssd` and
  # not `data`)
  include profile::docker
  include profile::docker_compose
}
