class profile::waagent {
  $filepath = '/etc/waagent.conf'
  $key_swap = 'ResourceDisk.EnableSwap'
  $key_swap_size_mb = 'ResourceDisk.SwapSizeMB'

  $swap_size_mb = lookup('waagent::swap::size_mb', {
    default_value => 0,
    value_type => Integer
  })

  # Make sure the file exists, should have been installed by azure vm provisionning
  file {$filepath:
    ensure => present,
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
  }

  $enable_swap = $swap_size_mb ? {
    0       => 'n',
    default => 'y',
  }

  file_line {"${filepath}-${key_swap}":
    ensure  => present,
    path    => $filepath,
    line    => "${key_swap}=${enable_swap}",
    match   => '^ResourceDisk\.EnableSwap=',
    require => File[$filepath],
  }

  file_line {"${filepath}-${key_swap_size_mb}":
    ensure  => present,
    path    => $filepath,
    line    => "${key_swap_size_mb}=${swap_size_mb}",
    match   => '^ResourceDisk\.SwapSizeMB=',
    require => File[$filepath],
  }
}
