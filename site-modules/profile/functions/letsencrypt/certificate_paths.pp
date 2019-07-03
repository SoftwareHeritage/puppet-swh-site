# Return the paths for the given letsencrypt certificate

function profile::letsencrypt::certificate_paths(
  String $basename,
) {
  $certs_directory = lookup('letsencrypt::certificates::directory')
  $basedir = "${certs_directory}/${basename}"

  Hash({
    cert      => "${basedir}/cert.pem",
    chain     => "${basedir}/chain.pem",
    fullchain => "${basedir}/fullchain.pem",
    privkey   => "${basedir}/privkey.pem",
  })
}
