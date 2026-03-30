# Installs Medusa backup tool on a node and its base configuration. Leaves
# instance-specific configuration for the instance.pp manifest.
#
# Assumes the profile::cassandra class was prior to this one

class profile::cassandra::medusa {
  $cassandra_user = $::profile::cassandra::cassandra_user
  $cassandra_data_dir = lookup('cassandra::base_data_directory')
  $cassandra_config_dir = lookup('cassandra::base_config_directory')
  $venv_path = "$cassandra_data_dir/venv-medusa"
  $medusa_run_backup_path = "$cassandra_data_dir/medusa_run_backup.sh"
  $rclone_config_path = "$cassandra_config_dir/medusa-rclone.conf"
  $cassandra_medusa_timer = lookup('cassandra::medusa::timer::calendar')

  $s3_access_key = lookup('cassandra::medusa::s3_access_key')
  $s3_secret_key = lookup('cassandra::medusa::s3_secret_key')
  $s3_endpoint = lookup('cassandra::medusa::s3_endpoint')
  $s3_bucket = lookup('cassandra::medusa::s3_bucket')
  $storage_encryption_passphrase_obfuscated = lookup('cassandra::medusa::storage_encryption_passphrase_obfuscated')

  # Create virtualenv
  ensure_packages ('python3-venv')
  exec { 'medusa_venv':
    command => "python3 -m venv '$venv_path'",
    path    => '/usr/bin',
    creates => "$venv_path",
    user    => "$cassandra_user",
    require => [User[$cassandra_user], Package['python3-venv']],
  }
  -> exec { 'medusa_pip_install':
    command => "'$venv_path/bin/pip' install 'cassandra-medusa[s3]'",
    path    => "$venv_path/bin:/usr/bin",
    creates => "$venv_path/bin/medusa",
    user    => "$cassandra_user",
  }

  # Install and configure rclone
  include ::profile::rclone

  file { "$rclone_config_path":
    ensure  => "present",
    owner   => "root",
    group   => "$cassandra_user",
    mode    => "0640",
    content => template('profile/cassandra/medusa-rclone.conf.erb'),
  }
  file { "/etc/fuse.conf":
    ensure  => "present",
    owner   => "root",
    group   => "root",
    mode    => "0644",
    content => template('profile/cassandra/fuse.conf.erb'),
  }

  # Install rclone systemd unit
  systemd::unit_file { 'cassandra-medusa-mount.service':
    content  => template('profile/cassandra/cassandra-medusa-mount.service.erb'),
    enable  => true,
    active  => true,
  }

  # Install medusa templated systemd unit
  file { "$medusa_run_backup_path":
    ensure  => "present",
    owner   => "root",
    group   => "$cassandra_user",
    mode    => "0754",
    content => template('profile/cassandra/medusa_run_backup.sh.erb'),
  }
  systemd::unit_file { 'cassandra-medusa@.service':
    content  => template('profile/cassandra/cassandra-medusa@.service.erb'),
    enable  => false,
    active  => false,
  }
  systemd::unit_file { 'cassandra-medusa@.timer':
    content  => template('profile/cassandra/cassandra-medusa@.timer.erb'),
    enable  => false,
    active  => false,
  }
}
