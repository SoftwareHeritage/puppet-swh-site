# A bot creating a thread for people to prepare their weekly meetings
class profile::weekly_reminder_bot {
  $command = '/usr/local/bin/weekly-reminder-bot'

  $weekly_planning_user = lookup('weekly_reminder_bot::user')
  $weekly_planning_cron = lookup('weekly_reminder_bot::cron')

  ['weekly-planning-bot',
   'weekly-management-bot',
  ].each |$bot| {
    $command = "/usr/local/bin/$bot";

    file {$command:
      ensure => present,
      mode   => '0755',
      owner  => 'root',
      group  => 'root',
      source => "puppet:///modules/profile/weekly_reminder_bot/${bot}",
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
