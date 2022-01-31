# A bot creating a thread for people to prepare their weekly planning in the centralized
# weekly report hedgedoc document
class profile::weekly_planning_bot {
  $command = '/usr/local/bin/weekly-planning-bot'

  $weekly_planning_user = lookup('weekly_planning_bot::user')
  $weekly_planning_cron = lookup('weekly_planning_bot::cron')

  $package = 'curl';

ensure_packages($package)

file {$command:
    ensure => present,
    mode   => '0755',
    owner  => 'root',
    group  => 'root',
    source => 'puppet:///modules/profile/weekly_planning_bot/weekly-planning-bot',
  }

  profile::cron::d {'weekly-planning-bot':
    command => "chronic ${command}",
    user    => $weekly_planning_user,
    *       => $weekly_planning_cron,
    require => [
      File[$command],
      Package[$package]
    ],
  }
}
