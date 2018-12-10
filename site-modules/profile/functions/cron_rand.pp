# Randomize a cron run
function profile::cron_rand (
  Hash[Enum['minute', 'hour', 'month', 'monthday', 'weekday'], Variant[Integer, String, Undef]] $data,
  String $seed,
) {
  $maxima = {
    'minute' => 60,
    'hour' => 24,
    'month' => 12,
    'monthday' => 31,
    'weekday' => 7,
  }

  Hash(
    map($maxima) |$key, $max| {
      [
        $key,
        case $data[$key] {
          'fqdn_rand': {fqdn_rand($max, "${seed}_${key}")}
          undef: {'*'}
          default: {$data[$key]}
        },
      ]
    }
  )
}
