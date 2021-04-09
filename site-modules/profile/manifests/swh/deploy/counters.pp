# Deployment of the swh.counters.api server
class profile::swh::deploy::counters {
  include ::profile::swh::deploy::base_counters

  $service_port = lookup('swh::remote_service::counters::port')
  $cache_directory = lookup('swh::deploy::counters::cache_directory')
  $cron_activate = lookup('swh::deploy::counters::refresh_cache::activate')
  $cron_expression = lookup('swh::deploy::counters::refresh_cache::cron')
  $static_history_file = lookup('swh::deploy::counters::cache_static_file')

  class { '::redis':
    bind                     => '127.0.0.1',
    save_db_to_disk_interval => { '30' => '1' },
  }

  file { $cache_directory:
    ensure => directory,
    owner  => 'swhstorage',
    group  => 'swhstorage',
    mode   => '0775',
  }

  ::profile::swh::deploy::rpc_server {'counters':
    executable => 'swh.counters.api.server:make_app_from_configfile()',
  }

  profile::prometheus::export_scrape_config {"swh-counters_${::fqdn}":
    job          => 'swh-counters',
    target       => "${::fqdn}:${service_port}",
    scheme       => 'http',
    metrics_path => '/metrics',
  }

  file { '/usr/local/bin/refresh_counters_cache.sh':
    ensure => present,
    owner  => 'swhstorage',
    group  => 'swhstorage',
    mode   => '0755',
    source => 'puppet:///modules/profile/swh/deploy/counters/refresh_counters_cache.sh',
  }


  if $cron_activate {
    ::profile::cron::d { 'refresh_counters_cache':
      command => "chronic /usr/local/bin/refresh_counters_cache.sh history.json ${static_history_file}",
      user    => 'swhstorage',
      *       => $cron_expression,
    }
  }

}
