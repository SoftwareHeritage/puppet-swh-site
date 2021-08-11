class role::swh_hypervisor inherits role::swh_server {
  include profile::megacli
  include profile::prometheus::pve_exporter
}
