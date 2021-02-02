# Create the system user for hedgedoc
class profile::hedgedoc::user {
  $user = 'hedgedoc'
  $group = 'hedgedoc'

  group {$group:
    system => true,
  }

  user {$user:
    system => true,
    gid    => $group,
    shell  => '/usr/sbin/nologin',
    home   => '/nonexistent',
  }

  # Cleanup for old versions of this manifest
  file {'/home/hedgedoc':
    ensure  => absent,
    purge   => true,
    recurse => true,
    force   => true,
  }
}
