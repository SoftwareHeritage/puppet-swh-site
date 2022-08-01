# Configuration for Azure workers

class role::swh_worker_azure inherits role::swh_worker {
  include ::profile::swh::deploy::objstorage_cloud
  include ::profile::waagent
}
