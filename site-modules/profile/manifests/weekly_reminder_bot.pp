# A bot creating a thread for people to prepare their weekly meetings
class profile::weekly_reminder_bot {
  $command = '/usr/local/bin/weekly-reminder-bot'

  $weekly_planning_user = lookup('weekly_reminder_bot::user')
  $weekly_bot_password = lookup('hedgedoc::weekly-bot::password')

  ['weekly-planning-bot',
   'weekly-management-bot',
  ].each |$bot| {
    $command = "/usr/local/bin/$bot";
    $weekly_planning_cron = lookup("weekly_reminder_bot::${bot}::cron")

    file {$command:
      ensure  => present,
      mode    => '0750',
      owner   => 'root',
      group   => 'root',
      content => template("profile/weekly_reminder_bot/${bot}.erb"),
    }

    profile::cron::d {$bot:
      command => "chronic ${command}",
      user    => $weekly_planning_user,
      *       => $weekly_planning_cron,
      require => [
        File[$command],
      ],
    }
  }
}
