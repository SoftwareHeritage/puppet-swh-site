# Deployment of the deployment private key for Software Heritage

class profile::swh::deploy {
  $deploy_group = lookup('swh::deploy::group')
  $deploy_directory = lookup('swh::deploy::directory')

  file {$deploy_directory:
    ensure  => directory,
    owner   => 'root',
    group   => $deploy_group,
    mode    => '0750',
    require => [
      Group[$deploy_group],
    ]
  }

  file {"${deploy_directory}/id_rsa":
    ensure  => present,
    content => lookup('swh::deploy::private_key'),
    owner   => 'root',
    group   => $deploy_group,
    mode    => '0640',
    require => [
      File[$deploy_directory],
      Group[$deploy_group],
    ],
  }

  file {"${deploy_directory}/id_rsa.pub":
    ensure  => present,
    content => lookup('swh::deploy::public_key'),
    owner   => 'root',
    group   => $deploy_group,
    mode    => '0640',
    require => [
      File[$deploy_directory],
      Group[$deploy_group],
    ],
  }
}
