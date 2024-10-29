# A bot creating a thread for people to prepare their weekly meetings
class profile::weekly_reminder_bot {
  $weekly_bot_user = lookup('weekly_reminder_bot::user')
  $weekly_bot_password = lookup('hedgedoc::weekly-bot::password')
  $weekly_bot_config_dir = lookup('weekly_reminder_bot::config_dir')
  $command = '/usr/local/bin/weekly-bot'

  file { $weekly_bot_config_dir:
    ensure => directory,
    mode   => '0750',
    owner  => 'root',
    group  => 'root',
  }

  file { "${weekly_bot_config_dir}/default":
    ensure  => present,
    mode    => '0640',
    owner   => 'root',
    group   => 'root',
    content => template('profile/weekly_reminder_bot/default.erb'),
    require => [
      File[$weekly_bot_config_dir],
    ],
  }

  file { $command:
    ensure  => present,
    mode    => '0750',
    owner   => 'root',
    group   => 'root',
    content => template('profile/weekly_reminder_bot/weekly-bot.erb'),
  }

  ['planning',
    'management',
  ].each |$bot| {
    $weekly_bot_cron = lookup("weekly_reminder_bot::${bot}::cron")

    profile::cron::d { "Weekly ${bot} reminder":
      command => "chronic ${command} ${bot}",
      user    => $weekly_bot_user,
      *       => $weekly_bot_cron,
      require => [
        File[$command,],
      ],
    }

    file { "${weekly_bot_config_dir}/${bot}":
      ensure  => present,
      mode    => '0640',
      owner   => 'root',
      group   => 'root',
      source  => "puppet:///modules/profile/weekly_reminder_bot/${bot}",
      require => [
        File[$weekly_bot_config_dir],
      ],
    }
  }

  ['weekly-planning-bot',
    'weekly-management-bot',
  ].each |$bot| {
    $deleted = "/usr/local/bin/${bot}"

    file { $deleted:
      ensure => absent,
    }
  }
}
