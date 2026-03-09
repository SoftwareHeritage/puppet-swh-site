# Kafkabackup, intended to run on Kafka brokers

class profile::kafka::kafkabackup_broker {
  # Create user and group
  $user = 'kafkabackup'
  $group = 'kafkabackup'
  $home = '/var/lib/kafkabackup'
  $venv_path = "$home/venv"
  $ssh_authorized_keys = lookup('swh::kafkabackup::ssh_pubkeys')
  $kafkabackup_frozendeps = "$home/kafkabackups-requirements-frozen.txt"
  $kafkabackup_frozendeps_url = "https://gitlab.softwareheritage.org/swh/infra/swh-apps/-/raw/master/apps/swh-kafkabackup/requirements-frozen.txt"

  group {$group:
    system => true,
  }
  -> user {$user:
    system     => true,
    gid        => $group,
    groups     => ['kafka'],
    shell      => '/usr/bin/bash',
    home       => $home,
  }
  -> file { $home:
    ensure  => 'directory',
    mode    => "0755",
    owner   => $user,
    group   => $group,
  }

  # Configure ssh access
  if($ssh_authorized_keys) {
    file { "$home/.ssh":
      ensure  => 'directory',
      mode    => "0750",
      owner   => $user,
      group   => $group,
      require => [User[$user], File[$home]],
    }
    each($ssh_authorized_keys) |$keyname, $key| {
      ssh_authorized_key { "$user $keyname":
        ensure  => 'present',
        user    => $user,
        key     => $key['key'],
        type    => $key['type'],
        require => File["$home/.ssh"],
      }
    }
  }

  # Configure virtualenv
  ensure_packages ('python3-venv')

  exec { 'kafkabackup_venv':
    command => "python3 -m venv '$venv_path'",
    path    => '/usr/bin',
    creates => "$venv_path",
    user    => "$user",
    require => [User[$user], File[$home], Package['python3-venv']],
  }
  -> exec { 'kafkabackup_install_uv':
    command => "'$venv_path/bin/pip' install 'uv'",
    path    => '/usr/bin',
    creates => "$venv_path/bin/uv",
    user    => "$user",
  }
  -> file { $kafkabackup_frozendeps:
    ensure =>  present,
    owner          => "$user",
    group          => "$group",
    mode           => '0644',
    source         => $kafkabackup_frozendeps_url,
  }
  -> exec { 'kafkabackup_pip_install':
    command => "'$venv_path/bin/uv' pip sync '$kafkabackup_frozendeps'",
    path    => "$venv_path/bin:/usr/bin",
    user    => "$user",
  }

  # Sudo configuration
  ::sudo::conf { 'kafkabackup':
    ensure   => present,
    content  => "$user  ALL=(root) NOPASSWD: /sbin/zfs list, /sbin/zfs snapshot data/kafka@*, /sbin/zfs destroy data/kafka@*, /usr/bin/mount -t zfs -o ro data/kafka@*, /usr/bin/umount /tmp/kafkabackup-*, /usr/bin/umount -t zfs data/kafka@*",
    priority => 50,
  }
}

