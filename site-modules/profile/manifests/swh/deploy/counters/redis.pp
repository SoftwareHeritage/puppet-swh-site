# Deployment of the redis backend for the counters
class profile::swh::deploy::counters::redis {
  class { '::redis':
    bind                     => [ '127.0.0.1', ip_for_network(lookup('internal_network')) ],
    save_db_to_disk_interval => { '30' => '1' },
  }
}
