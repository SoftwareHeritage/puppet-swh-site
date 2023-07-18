# A bot creating a thread for people to send their weekly report

class profile::weekly_report_bot {
  $command = '/usr/local/bin/weekly-report-bot'
  file {$command:
    ensure => absent,
  }
}
