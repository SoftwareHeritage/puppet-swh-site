# Checks that need to be supported on icinga2 agents
class profile::icinga2::objects::agent_checks {
  $plugins = {
    'check_journal' => {
      arguments => {
        '-f'  => {
          'value'  => '$journal_cursor_file$',
          'set_if' => '$journal_cursor_file$',
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
      }
    },
  }

  $swh_plugin_dir = '/usr/lib/nagios/plugins/swh'
  $swh_plugin_configfile = '/etc/icinga2/conf.d/swh-plugins.conf'

  $packages = [
    'python3-nagiosplugin',
    'python3-systemd',
    'monitoring-plugins-basic',
  ]
  package {$packages:
    ensure => present,
  }

  ['systemd-journal'].each |$group| {
    exec {"add nagios to group ${group}":
      command => "usermod -a -G ${group} nagios",
      unless  => "getent group ${group} | cut -d: -f4 | grep -qE (^|,)nagios(,|\$)",
      path    => ['/sbin', '/bin', '/usr/sbin', '/usr/bin'],
      notify  => Service['icinga2'],
      require => Package['icinga2'],
    }
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

    ::icinga2::object::checkcommand {$command:
      import    => ['plugin-check-command'],
      command   => [$command_path],
      arguments => $plugin['arguments'],
      vars      => $plugin['vars'],
      target    => $swh_plugin_configfile,
    }
  }
}
