# Base definition of a /etc/puppet-cron.d

define profile::cron::environment (
  String $target,
  Hash[String, String] $variables,
) {

  $variables.each | $key, $value | {
    concat_fragment { "profile::cron::${target}::_environment_$key":
      target  => "profile::cron::${target}",
      tag     => "profile::cron::${target}",
      order   => '5',
      content => "$key=$value\n",

    }
  }
}
