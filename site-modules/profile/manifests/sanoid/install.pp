class profile::sanoid::install {

  if versioncmp($::lsbmajdistrelease, '11') >= 0 {
    # Install the official package
    ensure_packages('sanoid')
  } else {
    # Buster and below, install a github release archive

    $version = '2.0.3'
    $archive_digest = '63115326695a00dc925d3ec8c307ed2543bb0a2479f2b15be3192bf2c7d50037'
    $archive_digest_type = 'sha256'

    $archive_url = "https://github.com/jimsalterjrs/sanoid/archive/refs/tags/v${version}.tar.gz"
    $archive_path = "/opt/sanoid-v${version}.tar.gz"
    $install_path = "/opt/sanoid-${version}"

    ensure_packages([
        'libcapture-tiny-perl', 
        'libconfig-inifiles-perl', 
        'zfsutils-linux',
        'lzop',
        'mbuffer',
        'pv',
    ])

    file { $install_path :
        ensure => directory,
        owner  => 'root',
        group  => 'root',
    }

    archive { 'sanoid':
        path            => $archive_path,
        extract         => true,
        extract_command => 'tar xzf %s --strip-components=1 --no-same-owner --no-same-permissions',
        source          => $archive_url,
        extract_path    => $install_path,
        checksum        => $archive_digest,
        checksum_type   => $archive_digest_type,
        creates         => "${install_path}/sanoid",
        cleanup         => true,
        user            => 'root',
        group           => 'root',
        require         => File[$install_path],
    }
    file { '/opt/sanoid' :
        ensure  => link,
        target  => $install_path,
        owner   => 'root',
        group   => 'root',
        require => Archive['sanoid'],
    }
    file { '/usr/sbin/sanoid' :
        ensure => link,
        target => '/opt/sanoid/sanoid',
        owner  => 'root',
        group  => 'root',
    }
    file { '/usr/sbin/syncoid' :
        ensure => link,
        target => '/opt/sanoid/syncoid',
        owner  => 'root',
        group  => 'root',
    }
    file { '/usr/sbin/findoid' :
        ensure => link,
        target => '/opt/sanoid/findoid',
        owner  => 'root',
        group  => 'root',
    }


  }

}
