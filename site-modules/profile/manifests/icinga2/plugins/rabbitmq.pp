# RabbitMQ icinga2 plugins

class profile::icinga2::plugins::rabbitmq {
  $packages = ['nagios-plugins-rabbitmq', 'libjson-perl']
  package {$packages:
    ensure => present,
  }

  $plugin_configfile = '/etc/icinga2/conf.d/rabbitmq-plugins.conf'

  $base_arguments = {
    '-H'         => '$rabbitmq_host$',
    '--port'     => '$rabbitmq_port$',
    '--user'     => '$rabbitmq_user$',
    '--password' => '$rabbitmq_password$',
  }

  $vhost_argument = {
    '--vhost' => {
      'value'  => '$rabbitmq_vhost$',
      'set_if' => '{{ var vhost = macro("$rabbitmq_vhost$"); return len(vhost) > 0 }}',
    },
  }

  $base_vars = {
    'rabbitmq_host'     => '$check_address$',
    'rabbitmq_port'     => '15672',
    'rabbitmq_user'     => 'guest',
    'rabbitmq_password' => 'guest',
  }

  $plugins = {
    rabbitmq_aliveness => {
      arguments => $base_arguments + $vhost_argument,
      vars      => $base_vars,
    },
    rabbitmq_connections => {
      arguments => $base_arguments,
      vars      => $base_vars,
    },
    rabbitmq_objects => {
      arguments => $base_arguments,
      vars      => $base_vars,
    },
    rabbitmq_overview => {
      arguments => $base_arguments,
      vars      => $base_vars,
    },
    rabbitmq_partition => {
      arguments => $base_arguments,
      vars      => $base_vars,
    },
    rabbitmq_queue => {
      arguments => $base_arguments + $vhost_argument,
      vars      => $base_vars,
    },
    rabbitmq_server => {
      arguments => $base_arguments + {
        '--node' => '$rabbitmq_node$',
      },
      vars      => $base_vars + {
        'rabbitmq_node' => '$check_address$',
      },
    },
    rabbitmq_shovels => {
      arguments => $base_arguments,
      vars      => $base_vars,
    },
    rabbitmq_watermark => {
      arguments => $base_arguments + $vhost_argument,
      vars      => $base_vars,
    },
  }

  $plugins.each |$command, $plugin| {
    ::icinga2::object::checkcommand {$command:
      import    => ['plugin-check-command', 'ipv4-or-ipv6'],
      command   => ["-:PluginContribDir + \"-rabbitmq/check_${command}\""],
      arguments => $plugin['arguments'],
      vars      => $plugin['vars'],
      target    => $plugin_configfile,
    }
  }
}
