# Configuration for Azure workers

class role::swh_worker_azure inherits role::swh_worker {
  include ::profile::swh::apt_config::azure
}
