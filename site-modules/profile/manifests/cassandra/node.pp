# Definition of a cassandra node
class profile::cassandra::node {
  $release = lookup('cassandra::release')

  class {'::cassandra::apache_repo':
    release => $release,
  }

  $basedir = '/srv/cassandra'
  $commitlogdir = "${basedir}/commitlog"
  $datadir = "${basedir}/data"
  $hintsdir = "${basedir}/hints"

  file {$basedir:
    ensure => 'directory',
    owner  => 'cassandra',
    group  => 'cassandra',
  }

  $baseline_settings = lookup('cassandra::baseline_settings')

  $cluster = lookup('cassandra::cluster')
  $cluster_settings = lookup('cassandra::clusters', Hash)[$cluster]

  $listen_network = lookup('cassandra::listen_network', Optional[String], 'first', undef)
  $listen_address = lookup('cassandra::listen_address', Optional[String], 'first', undef)
  $actual_listen_address = pick($listen_address, ip_for_network($listen_network))

  $listen_settings = {
    listen_address => $actual_listen_address,
    rpc_address    => $actual_listen_address
  }

  class {'::cassandra':
    baseline_settings     => $baseline_settings,
    commitlog_directory   => $commitlogdir,
    data_file_directories => [$datadir],
    hints_directory       => $hintsdir,
    settings              => $cluster_settings + $listen_settings,
  }
}
