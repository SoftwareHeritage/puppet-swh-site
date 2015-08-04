class profile::munin::plugins::postgresql {
  munin::plugin { 'postgres_autovacuum':
    ensure => link,
  }
  munin::plugin { 'postgres_bgwriter':
    ensure => link,
  }
  munin::plugin { 'postgres_cache_ALL':
    ensure => link,
    target => 'postgres_cache_',
  }
  munin::plugin { 'postgres_checkpoints':
    ensure => link,
  }
  munin::plugin { 'postgres_connections_ALL':
    ensure => link,
    target => 'postgres_connections_',
  }
  munin::plugin { 'postgres_connections_db':
    ensure => link,
  }
  munin::plugin { 'postgres_locks_ALL':
    ensure => link,
    target => 'postgres_locks_'
  }
  munin::plugin { 'postgres_querylength_ALL':
    ensure => link,
    target => 'postgres_querylength_',
  }
  munin::plugin { 'postgres_scans_ALL':
    ensure => link,
    target => 'postgres_scans_',
  }
  munin::plugin { 'postgres_size_ALL':
    ensure => link,
    target => 'postgres_size_',
  }
  munin::plugin { 'postgres_streaming_ALL':
    ensure => link,
    target => 'postgres_streaming_',
  }
  munin::plugin { 'postgres_transactions_ALL':
    ensure => link,
    target => 'postgres_transactions_',
  }
  munin::plugin { 'postgres_tuples_ALL':
    ensure => link,
    target => 'postgres_tuples_',
  }
  munin::plugin { 'postgres_users':
    ensure => link,
  }
  munin::plugin { 'postgres_xlog':
    ensure => link,
  }
}
