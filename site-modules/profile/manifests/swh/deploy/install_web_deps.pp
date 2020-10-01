# Install web dependencies (eventually backporting some packages)
define profile::swh::deploy::install_web_deps (
  Array $services       = [],
  String $pin_name      = $name,
  String $backport_list = 'swh::deploy::webapp::backported_packages',
  Array $swh_packages   = ['python3-swh.web'],
  String $ensure        = latest,
) {
  $task_backported_packages = lookup($backport_list)
  $pinned_packages = $task_backported_packages[$::lsbdistcodename]
  if $pinned_packages {
    ::apt::pin {$pin_name:
      explanation => "Pin ${pin_name} dependencies to backports",
      codename    => "${::lsbdistcodename}-backports",
      packages    => $pinned_packages,
      priority    => 990,
    }
    -> package {$swh_packages:
      ensure  => $ensure,
      require => Apt::Source['softwareheritage'],
      notify  => Service[$services],
    }
  } else {
    package {$swh_packages:
      ensure  => $ensure,
      require => Apt::Source['softwareheritage'],
      notify  => Service[$services],
    }
  }
}
