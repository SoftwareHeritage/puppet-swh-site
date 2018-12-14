# Add a cron.d snippet to the /etc/puppet-cron.d directory

define profile::cron::d(
  String $command,
  String $unique_tag = $title,
  String $target = 'default',
  Optional[Variant[Integer, String, Array[Variant[Integer, String]]]] $minute = undef,
  Optional[Variant[Integer, String, Array[Variant[Integer, String]]]] $hour = undef,
  Optional[Variant[Integer, String, Array[Variant[Integer, String]]]] $monthday = undef,
  Optional[Variant[Integer, String, Array[Variant[Integer, String]]]] $month = undef,
  Optional[Variant[Integer, String, Array[Variant[Integer, String]]]] $weekday = undef,
  Optional[Enum['@reboot', '@yearly', '@annually', '@monthly', '@weekly', '@daily', '@midnight', '@hourly']] $special = undef,
  String $user = 'root',
  Optional[String] $random_seed = undef,
) {
  include profile::cron

  $_params = {
    'minute' => $minute,
    'hour' => $hour,
    'monthday' => $monthday,
    'month' => $month,
    'weekday' => $weekday,
  }

  $_int_limits = {
    'minute'   => [0, 59],
    'hour'     => [0, 23],
    'monthday' => [1, 31],
    'month'    => [1, 12],
    'weekday'  => [0, 7],
  }

  $_str_values = {
    'month'   => ['jan', 'feb', 'mar', 'apr', 'may', 'jun', 'jul', 'aug', 'sep', 'oct', 'nov', 'dec'],
    'weekday' => ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'],
  }

  if $special != undef {
    $_defined_params = $_params.filter |$field, $value| { $value == undef }

    unless empty($_defined_params) {
      $_defined_fields = keys($_defined_params).each |$field| {"'${field}'"}.join(', ')
      fail("profile::cron::d parameter 'special' is exclusive with ${_defined_fields}.")
    }
  }

  $_parsed_params = $_params.map |$field, $value| {
    [$field] + profile::cron::validate_field(
      $field,
      pick_default($value, '*'),
      $_str_values[$field],
      $_int_limits[$field],
    )
  }

  $_parse_errors = $_parsed_params.filter |$value| { $value[1] == undef }.map |$value| { $value[2] }.flatten
  unless empty($_parse_errors) {
    $_str_parse_errors = $_parse_errors.join(', ')
    fail("Parse errors in profile::cron::d: ${_str_parse_errors}")
  }

  $_params_hash = $_parsed_params.map |$value| { $value[0,2] }.hash

  if !defined(Profile::Cron::File[$target]) {
    profile::cron::file {$target:}
  }

  concat_fragment {"profile::cron::${unique_tag}":
    order   => '10',
    content => template('profile/cron/snippet.erb'),
    tag     => "profile::cron::${target}",
  }
}
