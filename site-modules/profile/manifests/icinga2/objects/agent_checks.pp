# Checks that need to be supported on icinga2 agents
class profile::icinga2::objects::agent_checks {

  $prometheus_host = lookup('prometheus::server::fqdn')
  $prometheus_port = lookup('prometheus::server::listen_port')
  $prometheus_url = "http://${prometheus_host}:${prometheus_port}"

  $plugins = {
    'check_journal' => {
      arguments => {
        '-f'  => {
          'value'  => '$journal_cursor_file$',
          'set_if' => '{{ var filename = macro("$journal_cursor_file$"); return len(filename) > 0 }}',
        },
        '-w'  => '$journal_lag_warn$',
        '-c'  => '$journal_lag_crit$',
        '-wn' => {
          'value' => '$journal_lag_entries_warn$',
          'set_if' => '$journal_lag_entries_warn$',
        },
        '-cn' => {
          'value' => '$journal_lag_entries_crit$',
          'set_if' => '$journal_lag_entries_crit$',
        },
      },
      vars => {
        'journal_lag_warn' => 1200,
        'journal_lag_crit' => 3600,
      },
      sudo => true,
      sudo_user => 'root',
    },
    'check_newest_file_age' => {
      arguments => {
        '-d' => '$check_directory$',
        '-w' => '$check_directory_warn_age$',
        '-c' => '$check_directory_crit_age$',
        '-W' => {
          'set_if' => '$check_directory_missing_warn$',
        },
        '-C' => {
          'set_if' => '$check_directory_missing_crit$',
        },
      },
      vars => {
        'check_directory_warn_age' => 26,
        'check_directory_crit_age' => 52,
        'check_directory_missing_warn' => false,
        'check_directory_missing_crit' => true,
      },
      sudo => true,
      sudo_user => 'root',
    },
    'check_prometheus_metric' => {
      arguments => {
        '-H' => '$check_prometheus_metric_url$',
        '-q' => '$check_prometheus_metric_query$',
        '-w' => '$check_prometheus_metric_warning$',
        '-c' => '$check_prometheus_metric_critical$',
        '-n' => '$check_prometheus_metric_name$',
        '-m' => '$check_prometheus_comparison_method$',
        '-t' => '$check_prometheus_query_type$',
        '-O' => {
          'set_if' => '$check_prometheus_nan_ok$',
        },
        '-P' => {
          'set_if' => '$check_prometheus_perfdata$',
        },
      },
      vars => {
        'check_prometheus_metric_url'        => $prometheus_url,
        'check_prometheus_comparison_method' => 'ge',
        'check_prometheus_query_type'        => 'scalar',
        'check_prometheus_nan_ok'            => false,
        'check_prometheus_perfdat'           => true,
      }
    },
  }

  $plugin_dir = '/usr/lib/nagios/plugins'
  $swh_plugin_dir = "${plugin_dir}/swh"
  $swh_plugin_configfile = '/etc/icinga2/conf.d/swh-plugins.conf'

  $packages = [
    'python3-nagiosplugin',
    'python3-systemd',
    'monitoring-plugins-basic',
    'monitoring-plugins-systemd',  # in swh repository
  ]
  package {$packages:
    ensure => present,
  }

  file {$swh_plugin_dir:
    ensure  => 'directory',
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    recurse => true,
    purge   => true,
    require => Package[$packages],
  }

  $plugins.each |$command, $plugin| {
    $command_path = "${swh_plugin_dir}/${command}"
    file {$command_path:
      ensure  => present,
      owner   => 'root',
      group   => 'root',
      mode    => '0755',
      source  => "puppet:///modules/profile/icinga2/plugins/${command}",
      require => Package[$packages],

    }

    if $plugin['sudo'] {
      $sudo_user = $plugin['sudo_user']
      $icinga_command = ['sudo', '-u', $sudo_user, $command_path]

      ::sudo::conf { "icinga-${command}":
        ensure   => present,
        content  => "nagios ALL=(${sudo_user}) NOPASSWD: ${command_path}",
        priority => 50,
      }
    } else {
      $icinga_command = [$command_path]

      ::sudo::conf { "icinga-${command}":
        ensure  => absent,
      }
    }

    ::icinga2::object::checkcommand {$command:
      import    => ['plugin-check-command'],
      command   => $icinga_command,
      arguments => $plugin['arguments'],
      vars      => $plugin['vars'],
      target    => $swh_plugin_configfile,
    }
  }

  $check_command = "check_systemd"
  $check_command_path = "${plugin_dir}/${check_command}"
  ::icinga2::object::checkcommand {$check_command:
    import    => ['plugin-check-command'],
    command   => [ $check_command_path ],
    arguments => {
      '--unit'            => {
        value       => '$systemd_units$',
        description => 'Name of the systemd units that are being tested.',
        repeat_key  => true,
      },
      '--exclude'         => {
        value       => '$systemd_excludes$',
        description => '-:"Name of the systemd units to exclude from checks can be a regular expression)."',
        repeat_key  => true,
      },
      '--no-startup-time' => {
        set_if      => '{{ !macro("$systemd_check_startup_time$") }}',
        description => 'Whether to check the system startup time'
      },
    },
    vars => {
      systemd_units              => [],
      systemd_excludes           => [],
      systemd_check_startup_time => false,
    },
    target    => $swh_plugin_configfile,
    require   => Package[$packages],
  }
}
