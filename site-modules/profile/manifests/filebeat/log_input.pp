# Configure a log input for filebeat
define profile::filebeat::log_input(
  Array[String] $paths,
  Hash[String,String] $fields = {},
) {

  $input_configuration = [{
    'type'   => 'log',
    'paths'  => $paths,
    'fields' => $fields,
  }]

  file { "filebeat_input_${name}" :
    ensure  => present,
    path    => "${profile::filebeat::config_directory}/inputs.d/${name}.yml",
    content => inline_yaml($input_configuration),
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    require => [
      File["${profile::filebeat::config_directory}/inputs.d"],
      Package['filebeat'],
    ],
    notify  => Service['filebeat'],
  }

}
