# A bot creating a thread for people to send their monthly roadmap report

class profile::monthly_report_bot {
  $command = '/usr/local/bin/monthly-report-bot'

  $monthly_report_user = lookup('monthly_report_bot::user')
  $monthly_report_cron = lookup('monthly_report_bot::cron')

  file {$command:
    ensure => present,
    mode   => '0755',
    owner  => 'root',
    group  => 'root',
    source => 'puppet:///modules/profile/monthly_report_bot/monthly-report-bot',
  }

  profile::cron::d {'monthly-report-bot':
    command => $command,
    user    => $monthly_report_user,
    *       => $monthly_report_cron,
  }
}
