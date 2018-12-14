# A bot creating a thread for people to send their weekly report

class profile::weekly_report_bot {
  $command = '/usr/local/bin/weekly-report-bot'

  $weekly_report_user = lookup('weekly_report_bot::user')
  $weekly_report_cron = lookup('weekly_report_bot::cron')

  file {$command:
    ensure => present,
    mode   => '0755',
    owner  => 'root',
    group  => 'root',
    source => 'puppet:///modules/profile/weekly_report_bot/weekly-report-bot',
  }

  profile::cron::d {'weekly-report-bot':
    command => $command,
    user    => $weekly_report_user,
    *       => $weekly_report_cron,
  }
}
