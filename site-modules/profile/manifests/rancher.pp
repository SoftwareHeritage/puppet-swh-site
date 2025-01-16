# Rancher node configuration
class profile::rancher {
  include profile::zfs::rancher
  include profile::mountpoints
  include profile::kubernetes

  ensure_packages('pigz')
  ensure_packages('iptables')

  # Install the necessary 50-snapshotter.yaml configuration so rke2-agent.service
  # actually starts.
  $config_content = lookup('rancher::rke2::agent::config')

  file {['/etc/rancher', '/etc/rancher/rke2', '/etc/rancher/rke2/config.yaml.d']:
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

  file {'/etc/rancher/rke2/config.yaml.d/50-snapshotter.yaml':
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => inline_yaml($config_content),
  }

  $snapshotter = $config_content['snapshotter']

  if $snapshotter == 'zfs' {
    file {['/var/lib/rancher', '/var/lib/rancher/rke2', '/var/lib/rancher/rke2/agent']:
      ensure  => 'directory',
      owner   => 'root',
      group   => 'root',
      mode    => '0755',
      require => Zfs['data/rancher'],
    }
    -> file {'/var/lib/rancher/rke2/agent/containerd':
      ensure => 'directory',
      owner  => 'root',
      group  => 'root',
      mode   => '0711',
    }
    -> file {'/var/lib/rancher/rke2/agent/containerd/io.containerd.snapshotter.v1.zfs':
      ensure => 'directory',
      owner  => 'root',
      group  => 'root',
      mode   => '0700',
    }
  }

  $snapshots_cleaning = lookup('rancher::rke2::master::snapshots_cleaning', undef, undef, false)
  $snapshots_cleaning_minutes = lookup('rancher::rke2::master::snapshots_cleaning_minutes', undef, undef, 0)
  $etcd_snapshots_cleaning = '/usr/local/sbin/etcd-snapshots-cleaning.sh'

  if $snapshots_cleaning == true {
    file { '/etc/cron.d/etcd-snapshots-cleaning':
      ensure => absent,
    }
    -> file { $etcd_snapshots_cleaning:
      ensure => 'file',
      owner  => 'root',
      group  => 'root',
      mode   => '0754',
      source => 'puppet:///modules/profile/rancher/etcd-snapshots-cleaning.sh',
    }
    profile::cron::d { 'etcd-snapshots-cleaning':
      target  => 'etcd-snapshots-cleaning',
      command => "chronic ${etcd_snapshots_cleaning}",
      minute  => $snapshots_cleaning_minutes,
      hour    => '1,6,11,16,21',
    }
  }
}
