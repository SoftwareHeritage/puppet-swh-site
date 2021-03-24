# Deployment of the swh.counters.api server
class profile::swh::deploy::counters {
  include ::profile::swh::deploy::base_counters

  class { '::redis':
    bind                     => '127.0.0.1',
    save_db_to_disk_interval => { '30' => '1' },
  }

  ::profile::swh::deploy::rpc_server {'counters':
    executable => 'swh.counters.api.server:make_app_from_configfile()',
  }

  profile::prometheus::export_scrape_config {"swh-counters_${::fqdn}":
    job          => 'swh-counters',
    target       => "${::fqdn}:${swh::remote_service::counters::port}",
    scheme       => 'http',
    metrics_path => '/metrics',
  }

}
