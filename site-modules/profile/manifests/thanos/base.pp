# Base installation of thanos
class profile::thanos::base {
  $user = 'root'
  $group = 'root'

  $version = lookup('thanos::release::version')
  $archive_url = "https://github.com/thanos-io/thanos/releases/download/v${version}/thanos-${version}.linux-amd64.tar.gz"
  $archive_digest = lookup('thanos::release::digest')
  $archive_digest_type = lookup('thanos::release::digest_type')

  $install_basepath = "/opt/thanos"
  $install_dir = "${install_basepath}/${version}"

  $archive_path = "${install_basepath}/${version}.tar.gz"

  $current_symlink = "${install_basepath}/current"

  $config_dir = lookup('thanos::base::config_dir')

  file { [$install_basepath, $install_dir]:
    ensure  => 'directory',
    owner   => $user,
    group   => $group,
    mode    => '0644',
  }

  archive { 'thanos':
    path            => $archive_path,
    extract         => true,
    extract_command => 'tar xzf %s --strip-components=1 --no-same-owner --no-same-permissions',
    source          => $archive_url,
    extract_path    => $install_dir,
    checksum        => $archive_digest,
    checksum_type   => $archive_digest_type,
    creates         => "${install_dir}/thanos",
    cleanup         => true,
    user            => $user,
    group           => $group,
    require         => File[$install_dir],
  }

  -> file {$current_symlink:
    ensure      => 'link',
    target      => $install_dir,
  }

  file {$config_dir:
    ensure  => directory,
    owner   => $user,
    group   => 'prometheus',
    mode    => '0750',
    purge   => true,
    recurse => true,
  }
}
