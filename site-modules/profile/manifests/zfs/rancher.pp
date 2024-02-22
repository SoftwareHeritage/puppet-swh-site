# Handle /var/lib/rancher partition as zfs mountpoint
# On the vms, to reduce the disk usage and use local storage when the second hard
# drive is configured to a local storage in terraform
class profile::zfs::rancher {
  include ::profile::zfs::common
  # as it's for rancher, we consider the zpool['data'] is
  # already installed by profile::zfs::docker
  zfs { 'data/rancher':
    ensure      => present,
    atime       => 'off',
    compression => 'zstd',
    mountpoint  => '/var/lib/rancher',
    require     => Zpool['data'],
  }
  # This pool is used to create volumes that must be kept
  # if the server restarts. It's used by the local-path-provisioner tool
  zfs { 'data/volumes':
    ensure      => present,
    atime       => 'off',
    compression => 'zstd',
    mountpoint  => '/srv/kubernetes/volumes',
    require     => Zpool['data'],
  }

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
