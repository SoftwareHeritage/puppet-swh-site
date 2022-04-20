# SWH maven index exporter service
class role::swh_maven_index_exporter inherits role::swh_base {
  include profile::docker
  include profile::zfs::docker
  include profile::apache::simple_server
  include profile::maven_index_exporter
}
