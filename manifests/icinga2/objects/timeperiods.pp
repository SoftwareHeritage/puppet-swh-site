# Icinga2 timeperiod definitions
class profile::icinga2::objects::timeperiods {
  $timeperiod_file = '/etc/icinga2/conf.d/timeperiods.conf'

  ::icinga2::object::timeperiod {'24x7':
    import => ['legacy-timeperiod'],
    ranges => {
      monday    => '00:00-24:00',
      tuesday   => '00:00-24:00',
      wednesday => '00:00-24:00',
      thursday  => '00:00-24:00',
      friday    => '00:00-24:00',
      saturday  => '00:00-24:00',
      sunday    => '00:00-24:00',
    },
    target => $timeperiod_file,
  }
}
