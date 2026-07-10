class profile::openbao::install {
  $extract_path = '/usr/local/bin'
  $openbao_bin = "${extract_path}/bao"
  archive { "/tmp/openbao.tar.gz":
    ensure       => present,
    extract      => true,
    extract_path => $extract_path,
    source       => lookup('openbao::tarball_url'),
    cleanup      => true,
    checksum     => lookup('openbao::tarball_sha256'),
    checksum_type => 'sha256',
    # Only trigger download if:
    #  - openbao_version is unset (i.e. openbao isn't downloaded)
    #  - openbao_version is lower than the requested version
    creates      => $facts['openbao_version'] ? {
      undef   => $openbao_bin,
      default => versioncmp(lookup('openbao::version'), $facts['openbao_version']) > 0 ? {
        true    => undef,
        default => $openbao_bin
      }
    },
  }
  -> file { 'openbao_binary':
    path  => $openbao_bin,
    owner => 'root',
    group => 'root',
    mode  => '0755',
  }
}
