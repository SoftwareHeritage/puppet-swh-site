# A bot creating a thread for people to send their weekly report

class profile::weekly_report_bot {
  $command = '/usr/local/bin/weekly-report-bot'

  $weekly_report_user = lookup('weekly_report_bot::user')
  $weekly_report_hour = lookup('weekly_report_bot::cron::hour')
  $weekly_report_minute = lookup('weekly_report_bot::cron::minute')
  $weekly_report_weekday = lookup('weekly_report_bot::cron::weekday')

  file {$command:
    ensure => present,
    mode   => '0755',
    owner  => 'root',
    group  => 'root',
    source => 'puppet:///modules/profile/weekly_report_bot/weekly-report-bot',
  }

  cron {'weekly-report-bot':
    command => "su - ${weekly_report_user} -c ${command}",
    user    => 'root',
    hour    => $weekly_report_hour,
    minute  => $weekly_report_minute,
    weekday => $weekly_report_weekday,
  }
}
