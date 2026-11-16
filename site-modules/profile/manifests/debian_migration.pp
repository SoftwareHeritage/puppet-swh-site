# Install debian script to ease migration to the next stable version
class profile::debian_migration {
  # TODO: Use a switch case on the debian nature of the node
  case $facts['os']['distro']['codename'] {
    'bullseye': {
      $stable = "bookworm"
    }
    'bookworm': {
      $stable = "trixie"
    }

    default: { }
  }

  if $stable {
    $filename = "migrate-to-${stable}.sh"
    # In the mean time, the conditional have been pushed to the script
    file { "/usr/local/bin/${filename}":
      ensure => present,
      owner  => 'root',
      group  => 'root',
      mode   => '0700',
      source => "puppet:///modules/profile/debian/${filename}",
    }
  }
}
