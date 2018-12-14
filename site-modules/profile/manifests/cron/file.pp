# Base definition of a /etc/puppet-cron.d

define profile::cron::file (
  String $target = $title,
) {
  include profile::cron

  $file = "${profile::cron::directory}/${target}"
  concat_file {"profile::cron::${target}":
    path  => $file,
    owner => 'root',
    group => 'root',
    mode  => '0644',
    tag   => "profile::cron::${target}",
  }
  -> file {"/etc/cron.d/puppet-${target}":
    ensure => 'link',
    target => $file,
  }
  -> Exec['clean-cron.d-symlinks']

  concat_fragment {"profile::cron::${target}::_header":
    target  => "profile::cron::${target}",
    tag     => "profile::cron::${target}",
    order   => '00',
    content => "# Managed by puppet (module profile::cron), manual changes will be lost\n\n",
  }
}
