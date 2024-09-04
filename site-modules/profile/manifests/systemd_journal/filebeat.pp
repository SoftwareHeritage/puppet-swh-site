# Install filebeat with a systemd journal config
class profile::systemd_journal::filebeat {
  include profile::filebeat

  $input_configuration = [{
    'type' => 'journald',
    'id'   => 'journald',
  }]

  file {"${profile::filebeat::config_directory}/inputs.d/journald.yml":
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => inline_yaml($input_configuration),
    notify  => Service['filebeat'],
  }
}
