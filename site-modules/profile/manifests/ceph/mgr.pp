# ceph manager node
# The exporter must be activated first with `ceph mgr module enable prometheus`)

class profile::ceph::mgr {
  # default port from the ceph exporter
  $service_port = 9283

  profile::prometheus::export_scrape_config {'ceph-mgr':
    job          => 'ceph-mgr',
    target       => "${swh_hostname['internal_fqdn']}:${service_port}",
    scheme       => 'http',
    metrics_path => '/metrics',
  }

}
