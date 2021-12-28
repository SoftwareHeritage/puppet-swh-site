function profile::cron::validate_field(
  String $field,
  Variant[Integer, String, Array[Variant[Integer, String]]] $value,
  Optional[Array[String]] $valid_strings,
  Optional[Tuple[Integer, Integer]] $int_range,
  Optional[String] $seed = undef,
  Boolean $arrays_valid = true,
) >> Tuple[Optional[String], Array[String]] {

  if $value =~ Array and !$arrays_valid {
    return [undef, ["Cannot nest Arrays in value for ${field}"]]
  }

  $_valid_strings = pick_default($valid_strings, [])
  $_int_range =  pick_default($int_range, [0, 0])

  case $value {
    Array: {
      $ret = $value.map |$_value| {
        profile::cron::validate_field(
          $field,
          $_value,
          $valid_strings,
          $int_range,
          $seed,
          false,
        )
      }

      $_failed_values = $ret.filter |$_value| {
        $_value[0] == undef
      }

      if empty($_failed_values) {
        return [$ret.map |$_value| {$_value[0]}.join(','), []]
      } else {
        return [undef, $_failed_values.map |$_value| { $_value[1] }.flatten]
      }
    }

    *($_valid_strings + ['*']): {
      return [$value, []]
    }

    'fqdn_rand': {
      [$_min, $_max] = $_int_range
      return [$_min + fqdn_rand($_max - $_min + 1, "${seed}_${field}"), []]
    }

    /^\d+$/: {
      return profile::cron::validate_field(
        $field,
        Integer($value, 10),
        $valid_strings,
        $int_range,
        $seed,
        $arrays_valid,
      )
    }

    /[ ,]/: {
      return profile::cron::validate_field(
        $field,
        $value.split('[ ,]'),
        $valid_strings,
        $int_range,
        $seed,
        $arrays_valid,
      )
    }

    /^([0-9a-z]+)-([0-9a-z]+)$/: {
      $min_valid = profile::cron::validate_field(
        $field,
        $1,
        $valid_strings,
        $int_range,
        $seed,
        false,
      )

      $max_valid = profile::cron::validate_field(
        $field,
        $2,
        $valid_strings,
        $int_range,
        $seed,
        false,
      )

      $_errors = $min_valid[1] + $max_valid[1]
      if empty($_errors) {
        $_parsed_min = $min_valid[0]
        $_parsed_max = $max_valid[0]
        return ["${_parsed_min}-${_parsed_max}", []]
      } else {
        return [undef, $_errors]
      }
    }

    /^([0-9a-z]+)-([0-9a-z]+)\/(\d+)$/: {
      $min_valid = profile::cron::validate_field(
        $field,
        $1,
        $valid_strings,
        $int_range,
        $seed,
        false,
      )

      $max_valid = profile::cron::validate_field(
        $field,
        $2,
        $valid_strings,
        $int_range,
        $seed,
        false,
      )

      $interval_valid = profile::cron::validate_field(
        $field,
        Integer($3, 10),
        [],
        $int_range,
        $seed,
        false,
      )
      $_errors = $min_valid[1] + $max_valid[1] + $interval_valid[1]
      if empty($_errors) {
        $_parsed_min = $min_valid[0]
        $_parsed_max = $max_valid[0]
        $_parsed_interval = $interval_valid[0]
        return ["${_parsed_min}-${_parsed_max}/${_parsed_interval}", []]
      } else {
        return [undef, $_errors]
      }
    }

    /^(\*)\/(\d+)$/, /^(fqdn_rand)\/(\d+)$/: {
      $interval_valid = profile::cron::validate_field(
        $field,
        Integer($2, 10),
        [],
        $int_range,
        $seed,
        false,
      )
      if empty($interval_valid[1]) {
        $_parsed_interval = Integer($interval_valid[0], 10)
        if $1 == 'fqdn_rand' {
          $start = $_int_range[0] + fqdn_rand($_parsed_interval - 1, "${seed}_${field}")
          $end = $_int_range[1] + 1 + $start - $_parsed_interval
          return ["${start}-${end}/${_parsed_interval}", []]
        } else {
          return ["${1}/${_parsed_interval}", []]
        }
      } else {
        return $interval_valid
      }
    }

    String: {
      return [undef, ["Could not parse value ${value} for field ${field}"]]
    }

    Integer: {
      [$_min, $_max] = $_int_range
      if $_min <= $value and $value <= $_max {
        return [String($value), []]
      } else {
        return [undef, ["Value ${value} out of range ${_min}-${_max} for field ${field}"]]
      }
    }

    default: {
      return [undef, ["Unknown type ${value} for field ${field}"]]
    }
  }
}
