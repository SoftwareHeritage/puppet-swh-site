function profile::icinga2::literal_var(String $argument) >> String {
  # " => \"; \ => \\.
  $escaped_argument = regsubst($argument, '(["\\\\])', '\\\\\\1', 'G')
  "-:\"${escaped_argument}\""
}
