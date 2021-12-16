# Manage cloudinit configuration
class profile::cloudinit {

  # external fact installed by terraform
  if $::cloudinit_enabled {
    file { '/etc/cloud/cloud.cfg.d/99_modules.cfg':
      ensure => present,
      source => 'puppet:///modules/profile/cloud-init/modules.cfg',
      owner  => 'root',
      group  => 'root',
      mode   => '0644',
      notify => Service['cloud-init'],
    }

    service { 'cloud-init':
      ensure => running,
      enable => true,
    }
  }

}
