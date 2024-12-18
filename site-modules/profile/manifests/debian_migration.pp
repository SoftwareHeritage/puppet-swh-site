# Install debian script to ease migration to the next stable version
class profile::debian_migration {
  # TODO: Use a switch case on the debian nature of the node
  # In the mean time, the conditional have been pushed to the script
  file { '/usr/local/bin/migrate-to-bookworm.sh':
    ensure => present,
    owner  => 'root',
    group  => 'root',
    mode   => '0700',
    source => 'puppet:///modules/profile/debian/migrate-to-bookworm.sh',
  }
}
