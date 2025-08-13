# Install filebeat with a systemd journal config
class profile::systemd_journal::filebeat {
  include profile::filebeat

  $base_configuration = [{
      'type' => 'journald',
      'id'   => 'journald',
  }]
  $drop_event_configuration = lookup('filebeat::journald::drop_event', Hash, 'first', {})

  if $drop_event_configuration == {} {
    $input_configuration = $base_configuration
  } else {
    $input_configuration = $base_configuration.map |$hash| {
    deep_merge($hash, { 'processors' => ['drop_event' => $drop_event_configuration] }) }
  }

  file { "${profile::filebeat::config_directory}/inputs.d/journald.yml":
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => inline_yaml($input_configuration),
    notify  => Service['filebeat'],
  }
}
