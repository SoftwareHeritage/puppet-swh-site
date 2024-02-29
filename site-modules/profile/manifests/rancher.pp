# Rancher node configuration
class profile::rancher {
  include profile::zfs::rancher
  include profile::mountpoints
  include profile::kubernetes

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

  file {'/etc/rancher/rke2/config.yaml.d/50-snaphotter.yaml':
    ensure => 'absent',
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
}
