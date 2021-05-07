# Check the status of logstash service
# this is an agent check 
class profile::icinga2::objects::logstash_checks {
  $swh_plugin_dir = '/usr/lib/nagios/plugins/swh'
  $check_command = 'check_logstash_errors.sh'
  $check_command_path = "${swh_plugin_dir}/${check_command}"

  $swh_plugin_configfile = '/etc/icinga2/conf.d/swh-plugins.conf'

  file {$check_command_path:
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    source  => "puppet:///modules/profile/icinga2/plugins/${check_command}",
    require => File[$swh_plugin_dir]
  }


  ::icinga2::object::checkcommand {$check_command:
    import  => ['plugin-check-command'],
    command => $check_command_path,
    target  => $swh_plugin_configfile,
    require => File[$check_command_path]
  }

}
