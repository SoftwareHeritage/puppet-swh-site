# Handle /var/lib/rancher partition as zfs mountpoint
# On the vms, to reduce the disk usage and use local storage when the second hard
# drive is configured to a local storage in terraform
class profile::zfs::rancher {
  # as it's for rancher, we consider the zpool['data'] is
  # already installed by profile::zfs::docker
  zfs { 'data/rancher':
    ensure      => present,
    atime       => 'off',
    compression => 'zstd',
    mountpoint  => '/var/lib/rancher',
    require     => Zpool['data'],
  }

  # Install the necessary 50-snapshotter.yaml configuration so rke2-agent.service
  # actually starts.
  $config_content = lookup('rancher::rke2::agent::config')

  file {"/etc/rancher":
    ensure => directory,
    owner  => "root",
    group  => "root",
    mode   => '0755',
  }

  file {"/etc/rancher/rke2":
    ensure => directory,
    owner  => "root",
    group  => "root",
    mode   => '0755',
    require => File["/etc/rancher"],
  }

  file {"/etc/rancher/rke2/config.yaml.d":
    ensure => directory,
    owner  => "root",
    group  => "root",
    mode   => '0755',
    require => File["/etc/rancher/rke2"],
  }

  file {"/etc/rancher/rke2/config.yaml.d/50-snapshotter.yaml":
    owner  => "root",
    group  => "root",
    mode   => '0644',
    content => inline_yaml($config_content),
    # content => "{\n  \"snapshotter\": \"native\"\n}",
    require => File["/etc/rancher/rke2/config.yaml.d"],
  }
}
